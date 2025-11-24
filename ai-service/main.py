# main.py
"""
Kafka 기반 채점 서비스
- s3-download-url 토픽에서 이미지 URL 수신
- grading-status 토픽으로 시작/종료 메시지 전송
- student-answer 토픽으로 채점 결과 전송
- answer-explanation 토픽으로 LLM 해설 전송
"""

from __future__ import annotations
import asyncio
import json
import logging
import os
import sys
import tempfile
import uuid
from contextlib import asynccontextmanager
from pathlib import Path
from typing import List, Optional
from concurrent.futures import ThreadPoolExecutor
from api.schemas import (
    DownloadUrlRequest,
    GradingStartMessage,
    GradingEndMessage,
    StudentAnswerMessage,
    SectionAnswer,
    AnswerExplanationMessage,
    AnswerExplanationRequest
)

import uvicorn
from aiokafka import AIOKafkaConsumer, AIOKafkaProducer
from fastapi import FastAPI
from pydantic import BaseModel
import aiohttp

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ============================================================
# Kafka 설정
# ============================================================

KAFKA_BOOTSTRAP_SERVERS = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "3.34.214.133:9092")
TOPIC_DOWNLOAD_URL = "s3-download-url"
TOPIC_GRADING_STATUS = "grading-status"
TOPIC_STUDENT_ANSWER = "student-answer"
TOPIC_ANSWER_EXPLANATION = "answer-explanation"

# ============================================================
# 모델 경로 설정
# ============================================================

MODEL_DIR_1104 = os.getenv("MODEL_DIR_1104", "./models/Detection/legacy/Model_routing_1104")
MODEL_DIR_1004 = os.getenv("MODEL_DIR_1004", "./models/Detection/legacy/Model_routing_1004")
ANSWER_KEY_PATH = os.getenv("ANSWER_KEY_PATH", "./test/Hierarchical_crop/answers/yolo_answer.txt")
RESNET_ANSWER_1_PATH = os.getenv("RESNET_ANSWER_1_PATH", "./models/Recognition/models/answer_1_resnet.pth")
RESNET_ANSWER_2_PATH = os.getenv("RESNET_ANSWER_2_PATH", "./models/Recognition/models/answer_2_resnet.pth")
SECTION_PADDING = int(os.getenv("SECTION_PADDING", "50"))

# 챕터 파일 경로
CHAPTER_FILE_PATH = os.getenv("CHAPTER_FILE_PATH", "DB/chapter.txt")

# LLM 해설 생성 활성화 여부
ENABLE_LLM_EXPLANATION = os.getenv("ENABLE_LLM_EXPLANATION", "true").lower() == "true"

# ============================================================
# 전역 변수
# ============================================================

consumer: AIOKafkaConsumer | None = None
producer: AIOKafkaProducer | None = None
pipeline = None  # HierarchicalCropPipeline 인스턴스
chapter_mapper = None  # ChapterMapper 인스턴스
consume_task: asyncio.Task | None = None
thread_executor: ThreadPoolExecutor | None = None  # LLM 호출용 스레드 풀


# ============================================================
# LLM 해설 생성 함수
# ============================================================

def generate_explanation_sync(page_number: int, problem_number: int, user_answer: int) -> Optional[str]:
    """
    LLM을 통해 해설을 생성하는 동기 함수
    
    Args:
        page_number: 페이지 번호
        problem_number: 문제 번호
        user_answer: 사용자가 선택한 답안
        
    Returns:
        생성된 해설 텍스트 또는 None
    """
    try:
        from services.solution_llms import generate_explanation
        result = generate_explanation(
            page_number=page_number,
            problem_number=problem_number,
            user_answer=user_answer
        )
        return result
    except ImportError:
        logger.warning("LLM 해설 모듈을 찾을 수 없습니다. services/solution_llms.py를 확인하세요.")
        return None
    except Exception as e:
        logger.error(f"LLM 해설 생성 중 오류: {e}")
        return None


async def generate_explanation_async(page_number: int, problem_number: int, user_answer: int) -> Optional[str]:
    """
    LLM 해설 생성을 비동기로 실행
    
    Args:
        page_number: 페이지 번호
        problem_number: 문제 번호
        user_answer: 사용자가 선택한 답안
        
    Returns:
        생성된 해설 텍스트 또는 None
    """
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(
        thread_executor,
        generate_explanation_sync,
        page_number,
        problem_number,
        user_answer
    )


# ============================================================
# 유틸리티 함수
# ============================================================

async def download_image(url: str, dest_path: str) -> bool:
    """
    URL에서 이미지 다운로드
    """
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(url) as response:
                if response.status == 200:
                    content = await response.read()
                    with open(dest_path, 'wb') as f:
                        f.write(content)
                    logger.info(f"이미지 다운로드 완료: {dest_path}")
                    return True
                else:
                    logger.error(f"이미지 다운로드 실패: HTTP {response.status}")
                    return False
    except Exception as e:
        logger.error(f"이미지 다운로드 중 오류: {e}")
        return False


async def upload_image(local_path: str, upload_url: str) -> bool:
    """
    이미지를 S3에 업로드
    """
    try:
        with open(local_path, 'rb') as f:
            data = f.read()
        
        async with aiohttp.ClientSession() as session:
            async with session.put(upload_url, data=data) as response:
                if response.status in [200, 201, 204]:
                    logger.info(f"이미지 업로드 완료: {upload_url}")
                    return True
                else:
                    logger.error(f"이미지 업로드 실패: HTTP {response.status}")
                    return False
    except Exception as e:
        logger.error(f"이미지 업로드 중 오류: {e}")
        return False


def construct_upload_path(base_url: str, page_number: str, problem_number: str) -> str:
    """
    업로드 경로 생성
    
    형식: {uploadUrl}/{page_number}/{problem_number}/{page_number}_{problem_number}_section.jpg
    """
    return f"{base_url.rstrip('/')}/{page_number}/{problem_number}/{page_number}_{problem_number}_section.jpg"


def get_chapter_id_for_page(page_number_str: Optional[str]) -> int:
    """
    페이지 번호에 해당하는 chapter_id를 반환
    
    Args:
        page_number_str: 페이지 번호 문자열
        
    Returns:
        chapter_id 정수 (해당 챕터가 없으면 0)
    """
    global chapter_mapper
    
    if chapter_mapper is None:
        logger.warning("ChapterMapper가 초기화되지 않았습니다.")
        return 0
    
    return chapter_mapper.get_chapter_id_as_int_from_str(page_number_str)


# ============================================================
# Kafka 메시지 전송 함수
# ============================================================

async def send_grading_start(request: DownloadUrlRequest, book_id: int = 0):
    """채점 시작 메시지 전송"""
    message = GradingStartMessage(
        action="GRADING_STARTED",
        book_id=book_id,
        academy_user_id=request.academy_user_id,
        user_id=request.user_id,
        class_id=request.class_id,
        academy_id=request.academy_id,
        student_response_id=request.student_response_id
    )
    
    await producer.send_and_wait(
        TOPIC_GRADING_STATUS,
        value=message.model_dump_json().encode('utf-8')
    )
    logger.info(f"✅ 채점 시작 메시지 전송: student_response_id={request.student_response_id}")


async def send_grading_end(
    request: DownloadUrlRequest,
    book_id: int,
    total_question_count: int,
    total_score: int,
    response_start_page: int,
    response_end_page: int,
    unrecognized_response_count: int,
    is_error: bool = False
):
    """채점 종료 메시지 전송"""
    message = GradingEndMessage(
        action="ERROR" if is_error else "GRADING_COMPLETED",
        book_id=book_id,
        academy_user_id=request.academy_user_id,
        user_id=request.user_id,
        class_id=request.class_id,
        academy_id=request.academy_id,
        student_response_id=request.student_response_id,
        total_question_count=total_question_count,
        total_score=total_score,
        response_start_page=response_start_page,
        response_end_page=response_end_page,
        unrecognized_response_count=unrecognized_response_count
    )
    
    await producer.send_and_wait(
        TOPIC_GRADING_STATUS,
        value=message.model_dump_json().encode('utf-8')
    )
    logger.info(f"✅ 채점 종료 메시지 전송: student_response_id={request.student_response_id}, action={message.action}")


async def send_student_answer(
    request: DownloadUrlRequest,
    book_id: int,
    chapter_id: int,
    page_number: str,
    sections: List[SectionAnswer]
):
    """학생 답안 메시지 전송"""
    message = StudentAnswerMessage(
        student_response_id=request.student_response_id,
        academy_user_id=request.academy_user_id,
        book_id=book_id,
        chapter_id=chapter_id,
        page_number=page_number,
        sections=sections
    )
    
    await producer.send_and_wait(
        TOPIC_STUDENT_ANSWER,
        value=message.model_dump_json().encode('utf-8')
    )
    logger.info(f"✅ 학생 답안 메시지 전송: page={page_number}, chapter_id={chapter_id}, sections={len(sections)}")


async def send_answer_explanation(
    request: DownloadUrlRequest,
    book_id: int,
    chapter_id: int,
    page: int,
    question_number: int,
    user_answer: int,
    explanation: str,
    is_correct: bool,
    sub_question_number: int = 0,
    score: int = 1
):
    """답안 해설 메시지 전송"""
    message = AnswerExplanationMessage(
        student_response_id=request.student_response_id,
        academy_user_id=request.academy_user_id,
        book_id=book_id,
        chapter_id=chapter_id,
        page=page,
        question_number=question_number,
        sub_question_number=sub_question_number,
        user_answer=user_answer,
        explanation=explanation,
        is_correct=is_correct,
        score=score
    )
    
    await producer.send_and_wait(
        TOPIC_ANSWER_EXPLANATION,
        value=message.model_dump_json().encode('utf-8')
    )
    logger.info(f"✅ 답안 해설 메시지 전송: page={page}, question={question_number}, user_answer={user_answer}, is_correct={is_correct}")


# ============================================================
# 이미지 처리 함수
# ============================================================

async def process_image(request: DownloadUrlRequest) -> dict:
    """
    단일 이미지 처리
    
    HierarchicalCropPipeline이 section 이미지를 다음 경로에 직접 저장:
    {uploadUrl}/{page_number}/{problem_number}/{page_number}_{problem_number}_section.jpg
    
    Returns:
        처리 결과 딕셔너리
    """
    global pipeline
    
    # 임시 디렉토리 (이미지 다운로드용)
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        
        # 이미지 다운로드
        image_filename = f"image_{request.index}.jpg"
        image_path = temp_path / image_filename
        
        download_success = await download_image(request.downloadUrl, str(image_path))
        if not download_success:
            logger.error(f"이미지 다운로드 실패: {request.downloadUrl}")
            return {"success": False, "error": "download_failed"}
        
        # 출력 디렉토리 = uploadUrl (hierarchical_crop이 직접 올바른 경로에 저장)
        # uploadUrl이 로컬 경로인 경우 직접 사용
        # uploadUrl이 S3 URL인 경우 임시 디렉토리 사용 후 업로드 필요
        
        if request.uploadUrl.startswith('http'):
            # S3 presigned URL인 경우 - 임시 디렉토리에 저장 후 업로드
            output_dir = temp_path / "output"
            output_dir.mkdir(parents=True, exist_ok=True)
            need_upload = True
        else:
            # 로컬 경로인 경우 - 직접 해당 경로에 저장
            output_dir = Path(request.uploadUrl)
            output_dir.mkdir(parents=True, exist_ok=True)
            need_upload = False
        
        # HierarchicalCropPipeline으로 처리
        # section 이미지가 {output_dir}/{page}/{problem}/{page}_{problem}_section.jpg에 저장됨
        try:
            result = pipeline.process_page(str(image_path), output_dir)
            
            if result is None:
                logger.warning("페이지가 답지에 없어 처리되지 않았습니다.")
                return {"success": False, "error": "page_not_in_answer_key"}
            
            # S3 업로드가 필요한 경우
            if need_upload:
                page_number = result.get('page_number_ocr', 'unknown')
                
                for section in result['sections']:
                    section_crop_path = section.get('section_crop_path')
                    problem_number = section.get('problem_number_ocr')
                    
                    if section_crop_path and problem_number and os.path.exists(section_crop_path):
                        # S3 업로드 경로 생성
                        upload_path = construct_upload_path(
                            request.uploadUrl,
                            page_number,
                            problem_number
                        )
                        
                        # 이미지 업로드
                        await upload_image(section_crop_path, upload_path)
            
            return {
                "success": True,
                "result": result
            }
            
        except Exception as e:
            logger.error(f"이미지 처리 중 오류: {e}")
            import traceback
            traceback.print_exc()
            return {"success": False, "error": str(e)}


async def process_grading_request(request: DownloadUrlRequest):
    """
    전체 채점 요청 처리
    
    1. grading-start 전송
    2. 이미지 처리 (hierarchical_crop)
    3. student-answer 전송 (chapter_id 포함)
    4. LLM 해설 생성 및 answer-explanation 전송 (오답인 경우)
    5. grading-end 전송
    """
    book_id = 0  # TODO: 실제 book_id 매핑 필요
    
    # 1. 채점 시작 메시지 전송
    await send_grading_start(request, book_id)
    
    # 통계 변수
    total_question_count = 0
    total_score = 0
    response_start_page = None
    response_end_page = None
    unrecognized_response_count = 0
    
    try:
        # 2. 이미지 처리
        process_result = await process_image(request)
        
        if process_result["success"]:
            result = process_result["result"]
            
            page_number = result.get('page_number_ocr', 'unknown')
            
            # 페이지 번호로 chapter_id 조회
            chapter_id = get_chapter_id_for_page(page_number)
            if chapter_id > 0:
                logger.info(f"📖 페이지 {page_number} → 챕터 {chapter_id} 매핑됨")
            else:
                logger.warning(f"⚠️ 페이지 {page_number}에 해당하는 챕터를 찾을 수 없습니다.")
            
            # 페이지 범위 업데이트
            if page_number and page_number.isdigit():
                page_num_int = int(page_number)
                if response_start_page is None or page_num_int < response_start_page:
                    response_start_page = page_num_int
                if response_end_page is None or page_num_int > response_end_page:
                    response_end_page = page_num_int
            
            # Section 결과 변환 및 해설 생성
            sections = []
            explanation_tasks = []
            
            for section in result['sections']:
                problem_number = section.get('problem_number_ocr')
                answer = section.get('answer_number')
                correction = section.get('correction')
                
                total_question_count += 1
                
                if problem_number and answer:
                    is_correct = correction if correction is not None else False
                    
                    sections.append(SectionAnswer(
                        problem_number=str(problem_number),
                        answer=str(answer),
                        correction=is_correct
                    ))
                    
                    if is_correct:
                        total_score += 1
                    
                    # LLM 해설 생성 태스크 추가 (오답인 경우에만)
                    if ENABLE_LLM_EXPLANATION and not is_correct:
                        try:
                            page_int = int(page_number) if page_number.isdigit() else 0
                            problem_int = int(problem_number) if problem_number.isdigit() else 0
                            answer_int = int(answer) if answer.isdigit() else 0
                            
                            explanation_tasks.append({
                                'page': page_int,
                                'problem': problem_int,
                                'user_answer': answer_int,
                                'is_correct': is_correct,
                                'chapter_id': chapter_id
                            })
                        except ValueError:
                            logger.warning(f"해설 생성 스킵: 숫자 변환 실패 (page={page_number}, problem={problem_number}, answer={answer})")
                else:
                    unrecognized_response_count += 1
            
            # 3. student-answer 전송 (chapter_id 포함)
            if sections:
                await send_student_answer(
                    request=request,
                    book_id=book_id,
                    chapter_id=chapter_id,
                    page_number=page_number,
                    sections=sections
                )
            
            # 4. LLM 해설 생성 및 전송 (병렬 처리)
            if explanation_tasks:
                logger.info(f"📝 {len(explanation_tasks)}개 문제에 대해 LLM 해설 생성 중...")
                
                for task in explanation_tasks:
                    try:
                        # LLM 해설 생성
                        explanation = await generate_explanation_async(
                            page_number=task['page'],
                            problem_number=task['problem'],
                            user_answer=task['user_answer']
                        )
                        
                        if explanation:
                            # 해설 메시지 전송 (user_answer 포함)
                            await send_answer_explanation(
                                request=request,
                                book_id=book_id,
                                chapter_id=task['chapter_id'],
                                page=task['page'],
                                question_number=task['problem'],
                                user_answer=task['user_answer'],
                                explanation=explanation,
                                is_correct=task['is_correct'],
                                sub_question_number=0,
                                score=1 if task['is_correct'] else 0
                            )
                        else:
                            logger.warning(f"해설 생성 실패: page={task['page']}, problem={task['problem']}")
                            
                    except Exception as e:
                        logger.error(f"해설 생성/전송 중 오류: {e}")
        else:
            logger.error(f"이미지 처리 실패: {process_result.get('error')}")
            unrecognized_response_count += 1
        
        # 5. 채점 종료 메시지 전송
        await send_grading_end(
            request=request,
            book_id=book_id,
            total_question_count=total_question_count,
            total_score=total_score,
            response_start_page=response_start_page or 0,
            response_end_page=response_end_page or 0,
            unrecognized_response_count=unrecognized_response_count,
            is_error=not process_result["success"]
        )
        
    except Exception as e:
        logger.error(f"채점 처리 중 오류: {e}")
        import traceback
        traceback.print_exc()
        
        # 에러 시 채점 종료 메시지 전송
        await send_grading_end(
            request=request,
            book_id=book_id,
            total_question_count=total_question_count,
            total_score=total_score,
            response_start_page=response_start_page or 0,
            response_end_page=response_end_page or 0,
            unrecognized_response_count=unrecognized_response_count,
            is_error=True
        )


# ============================================================
# Kafka Consumer
# ============================================================

async def consume_messages():
    """Kafka 메시지 소비 루프"""
    try:
        async for msg in consumer:
            logger.info(f"메시지 수신: {msg.topic}")
            
            try:
                # JSON 파싱
                data = json.loads(msg.value)
                request = DownloadUrlRequest(**data)
                
                logger.info(f"처리 시작: student_response_id={request.student_response_id}, "
                           f"index={request.index}/{request.total}")
                
                # 비동기 처리
                await process_grading_request(request)
                
            except json.JSONDecodeError as e:
                logger.error(f"JSON 파싱 실패: {e}")
            except Exception as e:
                logger.error(f"메시지 처리 중 오류: {e}")
                import traceback
                traceback.print_exc()
                
    except asyncio.CancelledError:
        logger.info("Consumer 태스크 취소됨")
    except Exception as e:
        logger.error(f"Consumer 오류: {e}")


# ============================================================
# FastAPI 앱
# ============================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """FastAPI 라이프사이클 관리"""
    global consumer, producer, pipeline, chapter_mapper, consume_task, thread_executor
    
    # 스레드 풀 초기화 (LLM 호출용)
    thread_executor = ThreadPoolExecutor(max_workers=4)
    logger.info("✅ 스레드 풀 초기화 완료 (LLM 해설 생성용)")
    
    # ChapterMapper 초기화
    logger.info("ChapterMapper 초기화 중...")
    try:
        from services.chapter_mapper import ChapterMapper
        chapter_mapper = ChapterMapper(chapter_file_path=CHAPTER_FILE_PATH)
        logger.info(f"✅ ChapterMapper 초기화 완료: {len(chapter_mapper)}개 챕터 로드됨")
    except Exception as e:
        logger.warning(f"⚠️ ChapterMapper 초기화 실패: {e}")
        logger.warning("챕터 매핑 없이 실행됩니다 (chapter_id=0)")
    
    # HierarchicalCropPipeline 초기화
    logger.info("HierarchicalCropPipeline 초기화 중...")
    try:
        # 모듈 경로 추가
        sys.path.insert(0, os.getcwd())
        from services.hierarchical_crop import HierarchicalCropPipeline
        
        pipeline = HierarchicalCropPipeline(
            model_dir_1104=MODEL_DIR_1104,
            model_dir_1004=MODEL_DIR_1004,
            section_padding=SECTION_PADDING,
            answer_key_path=ANSWER_KEY_PATH if os.path.exists(ANSWER_KEY_PATH) else None,
            resnet_answer_1_path=RESNET_ANSWER_1_PATH if os.path.exists(RESNET_ANSWER_1_PATH) else None,
            resnet_answer_2_path=RESNET_ANSWER_2_PATH if os.path.exists(RESNET_ANSWER_2_PATH) else None
        )
        logger.info("✅ HierarchicalCropPipeline 초기화 완료")
    except Exception as e:
        logger.error(f"❌ HierarchicalCropPipeline 초기화 실패: {e}")
        raise
    
    # LLM 해설 모듈 확인
    if ENABLE_LLM_EXPLANATION:
        try:
            from services.solution_llms import generate_explanation
            logger.info("✅ LLM 해설 모듈 로드 완료")
        except ImportError:
            logger.warning("⚠️ LLM 해설 모듈을 찾을 수 없습니다. 해설 기능이 비활성화됩니다.")
    else:
        logger.info("ℹ️ LLM 해설 기능이 비활성화되어 있습니다.")
    
    # Kafka Consumer 초기화
    group_id = f"grading-service-{uuid.uuid4().hex[:8]}"
    
    consumer = AIOKafkaConsumer(
        TOPIC_DOWNLOAD_URL,
        bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
        group_id=group_id,
        value_deserializer=lambda v: v.decode("utf-8"),
        auto_offset_reset="earliest",
        enable_auto_commit=True
    )
    
    # Kafka Producer 초기화
    producer = AIOKafkaProducer(
        bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS
    )
    
    await consumer.start()
    await producer.start()
    logger.info(f"✅ Kafka 연결 완료 (group_id={group_id})")
    
    # Consumer 태스크 시작
    consume_task = asyncio.create_task(consume_messages())
    
    yield
    
    # 정리
    consume_task.cancel()
    await consumer.stop()
    await producer.stop()
    thread_executor.shutdown(wait=False)
    logger.info("🛑 Kafka 연결 종료")


app = FastAPI(
    title="채점 서비스",
    description="Kafka 기반 이미지 채점 서비스 (LLM 해설 포함)",
    lifespan=lifespan
)


@app.get("/")
async def root():
    """헬스 체크"""
    return {"status": "running", "service": "grading-service"}


@app.get("/health")
async def health():
    """상세 헬스 체크"""
    return {
        "status": "healthy",
        "kafka_consumer": consumer is not None,
        "kafka_producer": producer is not None,
        "pipeline": pipeline is not None,
        "chapter_mapper": chapter_mapper is not None,
        "chapter_count": len(chapter_mapper) if chapter_mapper else 0,
        "llm_explanation_enabled": ENABLE_LLM_EXPLANATION
    }


if __name__ == "__main__":
    # 파일명에 따라 자동으로 모듈명 결정
    module_name = Path(__file__).stem
    uvicorn.run(f"{module_name}:app", host="0.0.0.0", port=8000, reload=False)