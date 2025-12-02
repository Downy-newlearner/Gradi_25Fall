"""
Kafka 기반 채점 서비스
- s3-download-url 토픽에서 이미지 URL 수신
- grading-status 토픽으로 시작/종료 메시지 전송
- student-answer 토픽으로 채점 결과 전송
- /api/explanation 엔드포인트로 해설 요청 시 생성 후 Kafka 전송
- STS 방식으로 S3에 section 이미지 업로드 (서버 시작 시 자동 갱신)
"""

from __future__ import annotations
import asyncio
import json
import logging
import os
import sys
import tempfile
import uuid
import ssl
from contextlib import asynccontextmanager
from pathlib import Path
from typing import List, Optional, Dict, Any
from concurrent.futures import ThreadPoolExecutor

import uvicorn
from aiokafka import AIOKafkaConsumer, AIOKafkaProducer
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import aiohttp
import boto3
from botocore.client import Config

from api.schemas import (
    DownloadUrlRequest,
    GradingStartMessage,
    GradingEndMessage,
    StudentAnswerMessage,
    SectionAnswer,
    AnswerExplanationMessage,
    ExplanationRequest,
    ExplanationResponse,
    ExplanationResponseItem,
    BatchExplanationRequest,
    BatchExplanationResponse,
)

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
TOPIC_GRADING_START = "grading-start"
TOPIC_GRADING_END = "grading-end"
TOPIC_STUDENT_ANSWER = "student-answer"
TOPIC_ANSWER_EXPLANATION = "answer-explanation"

# ============================================================
# AWS / STS 설정
# ============================================================

STS_API_URL = os.getenv("STS_API_URL", "https://3.34.214.133/storage/sts/upload?folder=section")
STS_AUTH_TOKEN = os.getenv(
    "STS_AUTH_TOKEN",
    "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ3b25pd29yeSIsIm5hbWUiOiLsoJXshLHsm5AiLCJ1c2VySWQiOjMsImV4cCI6MTc2MzUzMTU2Nn0.Dxf6JPziYpnzQTy9h8FrzYiJYR0CmSptB0KbL_IQPZs"
)

STS_CREDENTIALS: Dict[str, Optional[str]] = {
    "access_key": None,
    "secret_key": None,
    "session_token": None,
    "expiration": None
}

AWS_REGION = "ap-northeast-2"
BUCKET_NAME = "gradibucket"

# ============================================================
# 모델 경로 설정
# ============================================================

MODEL_DIR_1104 = os.getenv("MODEL_DIR_1104", "./models/Detection/legacy/Model_routing_1104")
MODEL_DIR_1004 = os.getenv("MODEL_DIR_1004", "./models/Detection/legacy/Model_routing_1004")
ANSWER_KEY_PATH = os.getenv("ANSWER_KEY_PATH", "./test/Hierarchical_crop/answers/yolo_answer.txt")
RESNET_ANSWER_1_PATH = os.getenv("RESNET_ANSWER_1_PATH", "./models/Recognition/models/answer_1_resnet.pth")
RESNET_ANSWER_2_PATH = os.getenv("RESNET_ANSWER_2_PATH", "./models/Recognition/models/answer_2_resnet.pth")
SECTION_PADDING = int(os.getenv("SECTION_PADDING", "50"))

CHAPTER_FILE_PATH = os.getenv("CHAPTER_FILE_PATH", "DB/chapter.txt")

# 해설용 정답 파일 경로
ANSWER_FILE_PATH = os.getenv("ANSWER_FILE_PATH", "DB/answer.txt")

# ============================================================
# 전역 변수
# ============================================================

download_consumer: AIOKafkaConsumer | None = None
producer: AIOKafkaProducer | None = None
pipeline = None
chapter_mapper = None
download_consume_task: asyncio.Task | None = None
thread_executor: ThreadPoolExecutor | None = None

# 정답 데이터 캐시 (서버 시작 시 로드)
answer_cache: Dict[tuple, str] = {}


# ============================================================
# STS 자격증명 갱신 함수
# ============================================================

async def fetch_sts_credentials() -> bool:
    global STS_CREDENTIALS
    
    try:
        ssl_context = ssl.create_default_context()
        ssl_context.check_hostname = False
        ssl_context.verify_mode = ssl.CERT_NONE
        
        headers = {}
        if STS_AUTH_TOKEN:
            headers["Authorization"] = f"Bearer {STS_AUTH_TOKEN}"
        
        async with aiohttp.ClientSession() as session:
            async with session.get(
                STS_API_URL,
                headers=headers,
                ssl=ssl_context,
                timeout=aiohttp.ClientTimeout(total=30)
            ) as response:
                if response.status == 200:
                    data = await response.json()
                    
                    STS_CREDENTIALS["access_key"] = data.get("access_key_id")
                    STS_CREDENTIALS["secret_key"] = data.get("secret_access_key")
                    STS_CREDENTIALS["session_token"] = data.get("session_token")
                    STS_CREDENTIALS["expiration"] = data.get("expiration")
                    
                    logger.info(f"✅ STS 자격증명 갱신 완료. 만료 시간: {STS_CREDENTIALS['expiration']}")
                    return True
                else:
                    error_text = await response.text()
                    logger.error(f"STS 자격증명 갱신 실패: HTTP {response.status}, {error_text}")
                    return False
                    
    except asyncio.TimeoutError:
        logger.error("STS 자격증명 갱신 실패: 요청 타임아웃")
        return False
    except Exception as e:
        logger.error(f"STS 자격증명 갱신 중 오류: {e}")
        return False


# ============================================================
# S3 클라이언트 및 업로드 함수
# ============================================================

def get_s3_client():
    if not STS_CREDENTIALS["access_key"]:
        raise RuntimeError("STS 자격증명이 초기화되지 않았습니다.")
    
    return boto3.client(
        's3',
        aws_access_key_id=STS_CREDENTIALS["access_key"],
        aws_secret_access_key=STS_CREDENTIALS["secret_key"],
        aws_session_token=STS_CREDENTIALS["session_token"],
        region_name=AWS_REGION,
        config=Config(signature_version='s3v4')
    )


def build_s3_key(academy_user_id: int, student_response_id: int, problem_number: str, filename: str = "section.jpg") -> str:
    return f"section/{academy_user_id}/{student_response_id}/{problem_number}/{filename}"


async def upload_to_s3(file_path: str, s3_key: str) -> bool:
    try:
        s3_client = get_s3_client()
        
        with open(file_path, 'rb') as f:
            s3_client.put_object(
                Bucket=BUCKET_NAME,
                Key=s3_key,
                Body=f.read(),
                ContentType='image/jpeg'
            )
        
        logger.info(f"✅ S3 업로드 완료: {s3_key}")
        return True
        
    except Exception as e:
        logger.error(f"S3 업로드 실패: {s3_key}, 오류: {e}")
        return False


# ============================================================
# 유틸리티 함수
# ============================================================

def safe_int(value, default: int = 0) -> int:
    """
    문자열이나 숫자를 안전하게 정수로 변환
    "01" -> 1, "102" -> 102, 1 -> 1
    """
    if value is None:
        return default
    try:
        return int(value)
    except (ValueError, TypeError):
        return default


async def download_image(url: str, dest_path: str) -> bool:
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


def get_chapter_id_for_page(page_number_str: Optional[str]) -> int:
    global chapter_mapper
    
    if chapter_mapper is None:
        logger.warning("ChapterMapper가 초기화되지 않았습니다.")
        return 0
    
    return chapter_mapper.get_chapter_id_as_int_from_str(page_number_str)


# ============================================================
# 정답 파일 로드 및 조회 함수
# ============================================================

def load_answer_file(answer_file: str = None) -> Dict[tuple, str]:
    """
    answer.txt 파일을 로드하여 딕셔너리로 반환
    키는 (페이지번호 int, 문제번호 int) 튜플로 저장
    """
    if answer_file is None:
        answer_file = ANSWER_FILE_PATH
    
    mapping = {}
    
    if not os.path.exists(answer_file):
        logger.warning(f"정답 파일을 찾을 수 없음: {answer_file}")
        return mapping
    
    try:
        with open(answer_file, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                parts = [x.strip() for x in line.split(",")]
                if len(parts) >= 3:
                    page_int = safe_int(parts[0])
                    question_int = safe_int(parts[1])
                    answer = parts[2]
                    mapping[(page_int, question_int)] = answer
        
        logger.info(f"✅ 정답 파일 로드 완료: {len(mapping)}개 문제")
        return mapping
        
    except Exception as e:
        logger.error(f"정답 파일 읽기 실패: {e}")
        return mapping


def check_problem_exists(page_number: int, question_number: int) -> bool:
    """
    answer.txt에 해당 문제가 존재하는지 확인 (정수 비교)
    """
    global answer_cache
    
    page_int = safe_int(page_number)
    question_int = safe_int(question_number)
    
    exists = (page_int, question_int) in answer_cache
    
    if exists:
        logger.info(f"✅ 문제 존재 확인: page={page_int}, question={question_int}")
    else:
        logger.warning(f"❌ 문제 없음: page={page_int}, question={question_int}")
    
    return exists


def get_correct_answer(page_number: int, question_number: int) -> Optional[str]:
    """
    answer.txt에서 정답 조회 (정수 비교)
    """
    global answer_cache
    
    page_int = safe_int(page_number)
    question_int = safe_int(question_number)
    
    return answer_cache.get((page_int, question_int))


# ============================================================
# LLM 해설 생성 함수
# ============================================================

def generate_explanation_sync(page_number: int, problem_number: int, user_answer: int) -> Optional[str]:
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
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(
        thread_executor,
        generate_explanation_sync,
        page_number,
        problem_number,
        user_answer
    )


# ============================================================
# Kafka 메시지 전송 함수
# ============================================================

async def send_grading_start(request: DownloadUrlRequest, book_id: int = 1):
    message = GradingStartMessage(
        action="GRADING_STARTED",
        book_id=book_id,
        academy_user_id=request.academy_user_id,
        user_id=request.user_id or 0,
        class_id=request.class_id,
        academy_id=request.academy_id,
        student_response_id=request.student_response_id
    )
    
    await producer.send_and_wait(
        TOPIC_GRADING_START,
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
    message = GradingEndMessage(
        action="ERROR" if is_error else "GRADING_ENDED",
        book_id=book_id,
        academy_user_id=request.academy_user_id,
        user_id=request.user_id or 0,
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
        TOPIC_GRADING_END,
        value=message.model_dump_json().encode('utf-8')
    )
    logger.info(f"✅ 채점 종료 메시지 전송: student_response_id={request.student_response_id}, action={message.action}")


async def send_student_answer(
    request: DownloadUrlRequest,
    book_id: int,
    chapter_id: int,
    page_number: str,
    sections: List[SectionAnswer],
    score: int = 0
):
    page_int = safe_int(page_number)
    
    message = StudentAnswerMessage(
        student_response_id=request.student_response_id,
        academy_user_id=request.academy_user_id,
        book_id=book_id,
        chapter_id=chapter_id,
        page=page_int,
        score=score,
        sections=sections
    )
    
    await producer.send_and_wait(
        TOPIC_STUDENT_ANSWER,
        value=message.model_dump_json().encode('utf-8')
    )
    logger.info(f"✅ 학생 답안 메시지 전송: page={page_int}, chapter_id={chapter_id}, sections={len(sections)}, score={score}")


async def send_answer_explanation(
    student_response_id: int,
    academy_user_id: int,
    user_id: int,
    book_id: int,
    chapter_id: int,
    page_number: int,
    problem_number: int,
    sub_question_number: int,
    explanation: str
) -> bool:
    """
    답안 해설 메시지 전송 (REST API에서 호출)
    """
    try:
        message = AnswerExplanationMessage(
            student_response_id=student_response_id,
            academy_user_id=academy_user_id,
            user_id=user_id,
            book_id=book_id,
            chapter_id=chapter_id,
            page=page_number,
            question_number=problem_number,
            sub_question_number=sub_question_number,
            explanation=explanation
        )
        
        await producer.send_and_wait(
            TOPIC_ANSWER_EXPLANATION,
            value=message.model_dump_json().encode('utf-8')
        )
        logger.info(f"✅ 답안 해설 메시지 전송: page={page_number}, question={problem_number}")
        return True
    except Exception as e:
        logger.error(f"Kafka 해설 메시지 전송 실패: {e}")
        return False


# ============================================================
# 이미지 처리 함수 (임시 디렉토리에서만 처리, 저장 안함)
# ============================================================

async def process_image_and_upload(request: DownloadUrlRequest) -> dict:
    """
    이미지 처리 및 S3 업로드를 하나의 임시 디렉토리 컨텍스트에서 수행
    """
    global pipeline
    
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        
        image_filename = f"image_{request.index}.jpg"
        image_path = temp_path / image_filename
        
        download_success = await download_image(request.download_url, str(image_path))
        if not download_success:
            logger.error(f"이미지 다운로드 실패: {request.download_url}")
            return {"success": False, "error": "download_failed", "uploaded_keys": []}
        
        # 임시 출력 디렉토리 (임시 디렉토리 내에서만 사용)
        output_dir = temp_path / "output"
        output_dir.mkdir(parents=True, exist_ok=True)
        
        try:
            result = pipeline.process_page(str(image_path), output_dir)
            
            if result is None:
                logger.warning("페이지가 답지에 없어 처리되지 않았습니다.")
                return {"success": False, "error": "page_not_in_answer_key", "uploaded_keys": []}
            
            # S3 업로드 (임시 디렉토리가 삭제되기 전에 수행)
            uploaded_keys = []
            page_number = result.get('page_number_ocr', 'unknown')
            
            for section in result.get('sections', []):
                problem_number = section.get('problem_number_ocr')
                if not problem_number:
                    continue
                
                # problem_number를 문자열로 변환 (폴더명과 일치시키기 위해)
                problem_number_str = str(problem_number)
                
                section_image_path = output_dir / str(page_number) / problem_number_str / f"{page_number}_{problem_number_str}_section.jpg"
                
                if not section_image_path.exists():
                    logger.warning(f"Section 이미지를 찾을 수 없음: {section_image_path}")
                    continue
                
                s3_key = build_s3_key(
                    academy_user_id=request.academy_user_id,
                    student_response_id=request.student_response_id,
                    problem_number=problem_number_str,
                    filename="section.jpg"
                )
                
                success = await upload_to_s3(str(section_image_path), s3_key)
                if success:
                    uploaded_keys.append(s3_key)
            
            logger.info(f"📤 S3 업로드 완료: {len(uploaded_keys)}개 이미지")
            
            return {
                "success": True,
                "result": result,
                "uploaded_keys": uploaded_keys
            }
            
        except Exception as e:
            logger.error(f"이미지 처리 중 오류: {e}")
            import traceback
            traceback.print_exc()
            return {"success": False, "error": str(e), "uploaded_keys": []}


async def process_grading_request(request: DownloadUrlRequest):
    """
    전체 채점 요청 처리 (이미지는 로컬에 저장하지 않음)
    """
    book_id = 1
    
    await send_grading_start(request, book_id)
    
    total_question_count = 0
    total_score = 0
    response_start_page = None
    response_end_page = None
    unrecognized_response_count = 0
    
    try:
        process_result = await process_image_and_upload(request)
        
        if process_result["success"]:
            result = process_result["result"]
            
            page_number = result.get('page_number_ocr', 'unknown')
            
            chapter_id = get_chapter_id_for_page(page_number)
            if chapter_id > 0:
                logger.info(f"📖 페이지 {page_number} → 챕터 {chapter_id} 매핑됨")
            else:
                logger.warning(f"⚠️ 페이지 {page_number}에 해당하는 챕터를 찾을 수 없습니다.")
            
            page_int = safe_int(page_number)
            if page_int > 0:
                if response_start_page is None or page_int < response_start_page:
                    response_start_page = page_int
                if response_end_page is None or page_int > response_end_page:
                    response_end_page = page_int
            
            sections = []
            
            for section in result['sections']:
                problem_number = section.get('problem_number_ocr')
                answer = section.get('answer_number')
                correction = section.get('correction')
                
                total_question_count += 1
                
                if problem_number and answer:
                    is_correct = correction if correction is not None else False
                    
                    question_number_int = safe_int(problem_number)
                    
                    sections.append(SectionAnswer(
                        question_number=question_number_int,
                        sub_question_number=0,
                        answer=str(answer),
                        is_correct=is_correct
                    ))
                    
                    if is_correct:
                        total_score += 1
                else:
                    unrecognized_response_count += 1
            
            if sections:
                await send_student_answer(
                    request=request,
                    book_id=book_id,
                    chapter_id=chapter_id,
                    page_number=page_number,
                    sections=sections,
                    score=total_score
                )
            
        else:
            logger.error(f"이미지 처리 실패: {process_result.get('error')}")
            unrecognized_response_count += 1
        
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

async def consume_download_messages():
    try:
        async for msg in download_consumer:
            logger.info(f"메시지 수신: {msg.topic}")
            
            try:
                data = json.loads(msg.value)
                logger.debug(f"받은 메시지: {data}")
                
                request = DownloadUrlRequest(**data)
                
                logger.info(f"처리 시작: student_response_id={request.student_response_id}, "
                           f"index={request.index}/{request.total}")
                
                await process_grading_request(request)
                
            except json.JSONDecodeError as e:
                logger.error(f"JSON 파싱 실패: {e}")
            except Exception as e:
                logger.error(f"메시지 처리 중 오류: {e}")
                import traceback
                traceback.print_exc()
                
    except asyncio.CancelledError:
        logger.info("Download Consumer 태스크 취소됨")
    except Exception as e:
        logger.error(f"Download Consumer 오류: {e}")


# ============================================================
# FastAPI 앱
# ============================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    global download_consumer, producer, pipeline, chapter_mapper
    global download_consume_task, thread_executor, answer_cache
    
    thread_executor = ThreadPoolExecutor(max_workers=4)
    logger.info("✅ 스레드 풀 초기화 완료 (LLM 해설 생성용)")
    
    # 정답 파일 로드
    answer_cache = load_answer_file(ANSWER_FILE_PATH)
    
    logger.info("STS 자격증명 가져오는 중...")
    sts_success = await fetch_sts_credentials()
    if sts_success:
        logger.info("✅ STS 자격증명 초기화 완료")
    else:
        logger.warning("⚠️ STS 자격증명 초기화 실패. S3 업로드가 비활성화됩니다.")
    
    if STS_CREDENTIALS["access_key"]:
        try:
            s3_client = get_s3_client()
            s3_client.list_buckets()
            logger.info("✅ S3 연결 테스트 성공")
        except Exception as e:
            logger.warning(f"⚠️ S3 연결 테스트 실패: {e}")
            logger.warning("S3 업로드가 실패할 수 있습니다.")
    
    logger.info("ChapterMapper 초기화 중...")
    try:
        from services.chapter_mapper import ChapterMapper
        chapter_mapper = ChapterMapper(chapter_file_path=CHAPTER_FILE_PATH)
        logger.info(f"✅ ChapterMapper 초기화 완료: {len(chapter_mapper)}개 챕터 로드됨")
    except Exception as e:
        logger.warning(f"⚠️ ChapterMapper 초기화 실패: {e}")
        logger.warning("챕터 매핑 없이 실행됩니다 (chapter_id=0)")
    
    logger.info("HierarchicalCropPipeline 초기화 중...")
    try:
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
    
    try:
        from services.solution_llms import generate_explanation
        logger.info("✅ LLM 해설 모듈 로드 완료 (REST API로 해설 제공)")
    except ImportError:
        logger.warning("⚠️ LLM 해설 모듈을 찾을 수 없습니다. /api/explanation 엔드포인트가 비활성화됩니다.")
    
    download_group_id = f"grading-service-{uuid.uuid4().hex[:8]}"
    download_consumer = AIOKafkaConsumer(
        TOPIC_DOWNLOAD_URL,
        bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
        group_id=download_group_id,
        value_deserializer=lambda v: v.decode("utf-8"),
        auto_offset_reset="latest",
        enable_auto_commit=True,
        session_timeout_ms=60000,
        heartbeat_interval_ms=20000,
        max_poll_interval_ms=300000,
    )
    
    producer = AIOKafkaProducer(
        bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
        request_timeout_ms=60000,  # 60초 (기본값 40초)
        retry_backoff_ms=500,      # 재시도 간격
        max_request_size=1048576,  # 1MB
    )
    
    await download_consumer.start()
    await producer.start()
    logger.info(f"✅ Kafka 연결 완료")
    logger.info(f"   - Download Consumer group_id: {download_group_id}")
    logger.info(f"   - Producer topics: {TOPIC_GRADING_START}, {TOPIC_GRADING_END}, {TOPIC_STUDENT_ANSWER}, {TOPIC_ANSWER_EXPLANATION}")
    
    download_consume_task = asyncio.create_task(consume_download_messages())
    
    yield
    
    download_consume_task.cancel()
    await download_consumer.stop()
    await producer.stop()
    thread_executor.shutdown(wait=False)
    logger.info("🛑 Kafka 연결 종료")


app = FastAPI(
    title="채점 서비스",
    description="Kafka 기반 이미지 채점 서비스 (REST API로 해설 제공, STS 방식 S3 업로드)",
    lifespan=lifespan
)


@app.get("/")
async def root():
    return {"status": "running", "service": "grading-service"}


@app.get("/health")
async def health():
    s3_connected = False
    if STS_CREDENTIALS["access_key"]:
        try:
            s3_client = get_s3_client()
            s3_client.list_buckets()
            s3_connected = True
        except Exception:
            pass
    
    return {
        "status": "healthy",
        "kafka_download_consumer": download_consumer is not None,
        "kafka_producer": producer is not None,
        "pipeline": pipeline is not None,
        "chapter_mapper": chapter_mapper is not None,
        "chapter_count": len(chapter_mapper) if chapter_mapper else 0,
        "answer_cache_count": len(answer_cache),
        "s3_connected": s3_connected,
        "sts_expiration": STS_CREDENTIALS.get("expiration")
    }


@app.post("/refresh-sts")
async def refresh_sts():
    success = await fetch_sts_credentials()
    return {
        "success": success,
        "expiration": STS_CREDENTIALS.get("expiration")
    }


@app.post("/reload-answers")
async def reload_answers():
    """정답 파일 다시 로드"""
    global answer_cache
    answer_cache = load_answer_file(ANSWER_FILE_PATH)
    return {
        "success": True,
        "count": len(answer_cache)
    }


# ============================================================
# 해설 생성 REST API 엔드포인트
# ============================================================

@app.post("/api/explanation", response_model=ExplanationResponse)
async def generate_explanation_api(request: ExplanationRequest):
    """
    특정 문제에 대한 해설 생성 및 Kafka 전송
    
    answer.txt에서 문제 존재 여부를 확인한 후 해설을 생성합니다.
    (정수 변환하여 비교)
    
    Args:
        request: 해설 생성 요청 정보
            - student_response_id: 학생 응답 ID
            - academy_user_id: 학원 사용자 ID
            - user_id: 사용자 ID
            - page_number: 페이지 번호
            - question_number: 문제 번호
        
    Returns:
        생성된 해설 및 처리 결과 (단일 문제)
    """
    try:
        page_int = safe_int(request.page_number)
        question_int = safe_int(request.question_number)
        
        # answer.txt에서 문제 존재 여부 확인
        if not check_problem_exists(page_int, question_int):
            return ExplanationResponse(
                success=False,
                student_response_id=request.student_response_id,
                academy_user_id=request.academy_user_id,
                user_id=request.user_id,
                error=f"페이지 {page_int}, 문제 {question_int}은(는) answer.txt에 등록되지 않은 문제입니다."
            )
        
        # 기본값 설정
        book_id = 1
        chapter_id = get_chapter_id_for_page(str(page_int))
        sub_question_number = 0
        
        # user_answer는 0으로 설정 (해설 요청 시에는 사용자 답안 정보가 없음)
        # solution_llms.py에서 오답으로 처리되어 해설 생성됨
        user_answer = 0
        
        # LLM 해설 생성
        explanation_text = await generate_explanation_async(
            page_number=page_int,
            problem_number=question_int,
            user_answer=user_answer
        )
        
        if not explanation_text:
            explanation_text = "해설을 생성할 수 없습니다."
        
        # 응답 항목 생성
        explanation_item = ExplanationResponseItem(
            book_id=book_id,
            chapter_id=chapter_id,
            page=page_int,
            question_number=question_int,
            sub_question_number=sub_question_number,
            explanation=explanation_text
        )
        
        # Kafka로 해설 메시지 전송
        kafka_sent = await send_answer_explanation(
            student_response_id=request.student_response_id,
            academy_user_id=request.academy_user_id,
            user_id=request.user_id,
            book_id=book_id,
            chapter_id=chapter_id,
            page_number=page_int,
            problem_number=question_int,
            sub_question_number=sub_question_number,
            explanation=explanation_text
        )
        
        return ExplanationResponse(
            success=True,
            student_response_id=request.student_response_id,
            academy_user_id=request.academy_user_id,
            user_id=request.user_id,
            explanation=explanation_item,
            kafka_sent=kafka_sent
        )
        
    except Exception as e:
        logger.error(f"해설 생성 API 오류: {e}")
        import traceback
        traceback.print_exc()
        
        raise HTTPException(
            status_code=500,
            detail=f"해설 생성 중 오류가 발생했습니다: {str(e)}"
        )


@app.post("/api/explanation/batch", response_model=BatchExplanationResponse)
async def generate_explanation_batch_api(request: BatchExplanationRequest):
    """
    여러 문제에 대한 해설 일괄 생성 및 Kafka 전송
    """
    results = []
    success_count = 0
    failed_count = 0
    
    for req in request.requests:
        try:
            response = await generate_explanation_api(req)
            results.append(response)
            
            if response.success:
                success_count += 1
            else:
                failed_count += 1
                
        except Exception as e:
            logger.error(f"배치 해설 생성 중 오류: {e}")
            results.append(ExplanationResponse(
                success=False,
                student_response_id=req.student_response_id,
                academy_user_id=req.academy_user_id,
                user_id=req.user_id,
                error=str(e)
            ))
            failed_count += 1
    
    return BatchExplanationResponse(
        total=len(request.requests),
        success_count=success_count,
        failed_count=failed_count,
        results=results
    )


@app.post("/api/explanation/generate-only", response_model=ExplanationResponse)
async def generate_explanation_only_api(request: ExplanationRequest):
    """
    해설만 생성하고 Kafka 전송은 하지 않음
    """
    try:
        page_int = safe_int(request.page_number)
        question_int = safe_int(request.question_number)
        
        # answer.txt에서 문제 존재 여부 확인
        if not check_problem_exists(page_int, question_int):
            return ExplanationResponse(
                success=False,
                student_response_id=request.student_response_id,
                academy_user_id=request.academy_user_id,
                user_id=request.user_id,
                error=f"페이지 {page_int}, 문제 {question_int}은(는) answer.txt에 등록되지 않은 문제입니다."
            )
        
        book_id = 1
        chapter_id = get_chapter_id_for_page(str(page_int))
        
        explanation_text = await generate_explanation_async(
            page_number=page_int,
            problem_number=question_int,
            user_answer=0
        )
        
        if not explanation_text:
            explanation_text = "해설을 생성할 수 없습니다."
        
        explanation_item = ExplanationResponseItem(
            book_id=book_id,
            chapter_id=chapter_id,
            page=page_int,
            question_number=question_int,
            sub_question_number=0,
            explanation=explanation_text
        )
        
        return ExplanationResponse(
            success=True,
            student_response_id=request.student_response_id,
            academy_user_id=request.academy_user_id,
            user_id=request.user_id,
            explanation=explanation_item,
            kafka_sent=False
        )
        
    except Exception as e:
        logger.error(f"해설 생성 API 오류: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"해설 생성 중 오류가 발생했습니다: {str(e)}"
        )


if __name__ == "__main__":
    module_name = Path(__file__).stem
    uvicorn.run(f"{module_name}:app", host="0.0.0.0", port=8000, reload=False)