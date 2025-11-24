import os
from dotenv import load_dotenv
import logging
import json
from pathlib import Path
from typing import Dict, List, Optional
import cv2
import numpy as np
from datetime import datetime

# EasyOCR
import easyocr

load_dotenv()

# -----------------------------------------------------------
# 로깅 설정
# -----------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# -----------------------------------------------------------
# 메인 파이프라인 클래스
# -----------------------------------------------------------
class LLMDBPipelineFromImages:
    """저장된 이미지 구조에서 EasyOCR로 인식 → JSON 저장"""

    def __init__(self, output_json_path: str = "questions.json"):
        """
        Args:
            output_json_path: 저장할 JSON 파일 경로
        """
        # output_json_path를 먼저 설정
        self.output_json_path = output_json_path
        
        # EasyOCR 초기화 (한국어 + 영어)
        logger.info("EasyOCR 초기화 중...")
        self.reader = easyocr.Reader(['ko', 'en'], gpu=True)  # GPU 사용 (없으면 자동으로 CPU)
        
        # JSON 파일 초기화
        self._init_json_file()

        logger.info("LLMDBPipelineFromImages 초기화 완료 (EasyOCR 사용)")

    # -------------------------------------------------------
    # JSON 저장
    # -------------------------------------------------------
    def _init_json_file(self):
        """JSON 파일 초기화 (빈 배열로 생성)"""
        try:
            # 디렉토리가 없으면 생성
            json_path = Path(self.output_json_path)
            json_path.parent.mkdir(parents=True, exist_ok=True)
            
            # 파일이 이미 있으면 건너뛰기
            if json_path.exists():
                logger.info(f"기존 JSON 파일 사용: {self.output_json_path}")
                return
            
            # 새 파일 생성
            with open(self.output_json_path, 'w', encoding='utf-8') as f:
                json.dump([], f, ensure_ascii=False, indent=2)
            logger.info(f"JSON 파일 생성 완료: {self.output_json_path}")
        except Exception as e:
            logger.error(f"JSON 파일 초기화 실패: {e}")

    def save_to_json(self, question: Dict):
        """질문을 JSON 파일에 추가"""
        try:
            # 파일이 없으면 빈 배열로 시작
            json_path = Path(self.output_json_path)
            if json_path.exists():
                with open(self.output_json_path, 'r', encoding='utf-8') as f:
                    try:
                        questions_data = json.load(f)
                    except json.JSONDecodeError:
                        logger.warning("JSON 파일이 손상되었습니다. 새로 생성합니다.")
                        questions_data = []
            else:
                logger.info("JSON 파일이 없습니다. 새로 생성합니다.")
                questions_data = []
            
            # 새로운 질문 추가
            questions_data.append(question)
            
            # 디렉토리 확인 및 생성
            json_path.parent.mkdir(parents=True, exist_ok=True)
            
            # 파일에 저장
            with open(self.output_json_path, 'w', encoding='utf-8') as f:
                json.dump(questions_data, f, ensure_ascii=False, indent=2)
            
            logger.info(f"JSON 저장 완료: 페이지 {question.get('page_number')} - 문제 {question.get('problem_number')}")
        except Exception as e:
            logger.error(f"JSON 저장 실패: {e}")

    # -------------------------------------------------------
    # EasyOCR 유틸
    # -------------------------------------------------------
    def extract_text_with_easyocr(self, image_path: str, lang: str = 'ko') -> str:
        """EasyOCR을 사용하여 이미지에서 텍스트 추출
        
        Args:
            image_path: 이미지 파일 경로
            lang: 'ko' (한국어) 또는 'en' (영어) - 참고용 (EasyOCR은 둘 다 지원)
            
        Returns:
            str: 추출된 텍스트
        """
        try:
            # 이미지 파일 존재 확인
            if not Path(image_path).exists():
                logger.warning(f"이미지 파일이 존재하지 않습니다: {image_path}")
                return ""
            
            # EasyOCR readtext 실행
            # 결과 형식: [([bbox], text, confidence), ...]
            result = self.reader.readtext(image_path)
            
            # 결과에서 텍스트만 추출
            if result:
                texts = []
                for detection in result:
                    # detection[1]이 텍스트, detection[2]가 신뢰도
                    text = detection[1]
                    if text:
                        texts.append(text)
                return '\n'.join(texts)
            return ""
        except Exception as e:
            logger.error(f"EasyOCR 추출 실패 ({image_path}): {e}")
            return ""

    def extract_number_with_easyocr(self, image_path: str) -> str:
        """EasyOCR을 사용하여 숫자만 추출
        
        Args:
            image_path: 이미지 파일 경로
            
        Returns:
            str: 추출된 숫자
        """
        try:
            text = self.extract_text_with_easyocr(image_path, lang='en')
            # 숫자만 추출
            import re
            numbers = re.findall(r'\d+', text)
            return numbers[0] if numbers else ""
        except Exception as e:
            logger.error(f"숫자 추출 실패 ({image_path}): {e}")
            return ""

    # -------------------------------------------------------
    # 페이지 번호 인식
    # -------------------------------------------------------
    def get_page_number(self, page_dir: Path) -> Optional[str]:
        """페이지 번호 이미지에서 번호 추출
        
        Args:
            page_dir: 페이지 디렉토리 (예: output/database_images/학생이 푼 문제(실전 모의고사)-1)
            
        Returns:
            인식된 페이지 번호
        """
        page_numbers_dir = page_dir / "page_numbers"
        
        # 방법 1: page_numbers 디렉토리에서 찾기
        if page_numbers_dir.exists():
            # _page_number.jpg 파일 찾기
            page_num_files = list(page_numbers_dir.glob("*_page_number.jpg"))
            if page_num_files:
                page_num_path = page_num_files[0]
                page_number = self.extract_number_with_easyocr(str(page_num_path))
                if page_number:
                    logger.info(f"페이지 번호 인식 (이미지): {page_number}")
                    return page_number
        
        # 방법 2: page_numbers 디렉토리가 없으면 폴더명에서 추출
        logger.warning(f"page_numbers 디렉토리가 없습니다. 폴더명에서 페이지 번호 추출 시도: {page_dir.name}")
        import re
        # 폴더명에서 숫자 찾기 (예: "학생이 푼 문제(실전 모의고사) - 35" → "35")
        numbers = re.findall(r'\d+', page_dir.name)
        if numbers:
            # 마지막 숫자를 페이지 번호로 사용
            page_number = numbers[-1]
            logger.info(f"페이지 번호 추출 (폴더명): {page_number}")
            return page_number
        
        logger.error(f"페이지 번호를 찾을 수 없습니다: {page_dir}")
        return None

    # -------------------------------------------------------
    # Section 내 문제 처리
    # -------------------------------------------------------
    def process_section(self, section_dir: Path, page_number: str) -> List[Dict]:
        """Section 디렉토리 내의 모든 문제를 OCR 인식
        
        Args:
            section_dir: Section 디렉토리 (예: section00)
            page_number: 페이지 번호
            
        Returns:
            인식된 문제 리스트
        """
        results = []
        
        # prob_{order}_number.jpg 파일들을 찾아서 정렬
        prob_number_files = sorted(section_dir.glob("prob_*_number.jpg"))
        
        for prob_num_file in prob_number_files:
            # prob_{order} 추출
            prob_order = prob_num_file.stem.split("_")[1]
            
            logger.info(f"  문제 {prob_order} 처리 중...")
            
            result = {
                "page_number": page_number,
                "problem_number": None,
                "korean_content": None,
                "english_content": None,
                "script": None
            }
            
            # 1. 문제 번호 인식 (prob_{order}_number.jpg)
            problem_number = self.extract_number_with_easyocr(str(prob_num_file))
            result["problem_number"] = problem_number
            logger.info(f"    문제 번호: {problem_number}")
            
            # 2. 한국어 지문 인식 (prob_{order}_korean_content.jpg)
            korean_file = section_dir / f"prob_{prob_order}_korean_content.jpg"
            if korean_file.exists():
                korean_text = self.extract_text_with_easyocr(str(korean_file), lang='ko')
                result["korean_content"] = korean_text
                logger.info(f"    한국어 지문: {len(korean_text)}자")
            else:
                logger.info(f"    한국어 지문: 없음")
            
            # 3. 영어 지문 인식 (prob_{order}_english_content.jpg)
            english_file = section_dir / f"prob_{prob_order}_english_content.jpg"
            if english_file.exists():
                english_text = self.extract_text_with_easyocr(str(english_file), lang='en')
                result["english_content"] = english_text
                logger.info(f"    영어 지문: {len(english_text)}자")
            else:
                logger.info(f"    영어 지문: 없음")
            
            # 4. Script 인식 (prob_{order}_script.jpg)
            script_file = section_dir / f"prob_{prob_order}_script.jpg"
            if script_file.exists():
                # 한/영 혼합 가능하므로 한국어 모드로 실행
                script_text = self.extract_text_with_easyocr(str(script_file))
                result["script"] = script_text
                logger.info(f"    Script: {len(script_text)}자")
            else:
                logger.info(f"    Script: 없음")
            
            # 5. Answer option 인식 (prob_{order}_answer_option.jpg) - 선택사항
            answer_file = section_dir / f"prob_{prob_order}_answer_option.jpg"
            if answer_file.exists():
                # 한/영 혼합 가능하므로 한국어 모드로 실행
                answer_text = self.extract_text_with_easyocr(str(answer_file))
                result["answer_option"] = answer_text
                logger.info(f"    선택지: {len(answer_text)}자")
            
            results.append(result)
        
        return results

    # -------------------------------------------------------
    # 페이지 처리
    # -------------------------------------------------------
    def process_page(self, page_dir: Path):
        """한 페이지 디렉토리를 처리
        
        Args:
            page_dir: 페이지 디렉토리 경로 (예: output/database_images/학생이 푼 문제(실전 모의고사)-1)
        """
        try:
            logger.info(f"\n{'='*60}")
            logger.info(f"페이지 처리 시작: {page_dir.name}")
            logger.info(f"{'='*60}")
            
            # 1. 페이지 번호 인식
            page_number = self.get_page_number(page_dir)
            if not page_number:
                logger.error(f"페이지 번호를 찾을 수 없습니다: {page_dir}")
                return
            
            # 2. 모든 section 디렉토리 찾기
            section_dirs = sorted([d for d in page_dir.iterdir() 
                                  if d.is_dir() and d.name.startswith("section")])
            
            logger.info(f"Section 개수: {len(section_dirs)}")
            
            # 3. 각 section 처리
            total_questions = 0
            for section_dir in section_dirs:
                logger.info(f"\n{section_dir.name} 처리 중...")
                questions = self.process_section(section_dir, page_number)
                
                # JSON에 저장
                for question in questions:
                    self.save_to_json(question)
                    total_questions += 1
            
            logger.info(f"\n✅ 페이지 처리 완료: {total_questions}개 문제 저장")
            
        except Exception as e:
            logger.error(f"페이지 처리 중 오류 발생 ({page_dir}): {e}", exc_info=True)

    # -------------------------------------------------------
    # 다중 페이지 처리
    # -------------------------------------------------------
    def process_all_pages(self, base_dir: str):
        """모든 페이지 디렉토리를 순차적으로 처리
        
        Args:
            base_dir: 최상위 디렉토리 경로 (예: output/database_images)
        """
        logger.info("\n" + "="*60)
        logger.info("다중 페이지 처리 시작")
        logger.info("="*60)
        
        base_path = Path(base_dir)
        if not base_path.exists():
            logger.error(f"디렉토리가 존재하지 않습니다: {base_dir}")
            return
        
        # 모든 페이지 디렉토리 찾기
        # database_images/{이미지 파일 이름}/ 형태의 디렉토리들
        page_dirs = []
        for item in sorted(base_path.iterdir()):
            if not item.is_dir():
                continue
            
            # 디렉토리 내부 확인
            has_page_numbers = (item / "page_numbers").exists()
            has_sections = any(d.name.startswith("section") for d in item.iterdir() if d.is_dir())
            
            if has_page_numbers or has_sections:
                page_dirs.append(item)
                status = []
                if has_page_numbers:
                    status.append("page_numbers ✅")
                if has_sections:
                    section_count = len([d for d in item.iterdir() if d.is_dir() and d.name.startswith("section")])
                    status.append(f"sections({section_count}) ✅")
                logger.debug(f"페이지 발견: {item.name} - {' '.join(status)}")
        
        logger.info(f"총 {len(page_dirs)}개 페이지 발견")
        
        if not page_dirs:
            logger.warning(f"페이지 디렉토리를 찾을 수 없습니다: {base_dir}")
            logger.info(f"\n예상 구조:")
            logger.info(f"  {base_dir}/")
            logger.info(f"    └── {{이미지_파일_이름}}/")
            logger.info(f"        ├── page_numbers/")
            logger.info(f"        │   └── {{이미지_파일_이름}}_page_number.jpg")
            logger.info(f"        └── section00/")
            logger.info(f"            └── prob_XX_*.jpg")
            return

        # 각 페이지 처리
        total_start_time = datetime.now()
        
        for idx, page_dir in enumerate(page_dirs, 1):
            logger.info(f"\n[{idx}/{len(page_dirs)}] 처리 중...")
            self.process_page(page_dir)

        total_end_time = datetime.now()
        elapsed_time = (total_end_time - total_start_time).total_seconds()
        
        logger.info("\n" + "="*60)
        logger.info("전체 처리 완료")
        logger.info("="*60)
        logger.info(f"처리 시간: {elapsed_time:.2f}초 ({elapsed_time/60:.2f}분)")
        logger.info(f"저장 위치: {self.output_json_path}")
        logger.info("="*60)

# -----------------------------------------------------------
# 실행 예시
# -----------------------------------------------------------
if __name__ == "__main__":
    import os

    # 경로 설정
    base_dir = "./DB/output/database2"  # 페이지 디렉토리들이 있는 최상위 디렉토리
    output_json_path = "./DB/database2.json"

    # 파이프라인 실행
    pipeline = LLMDBPipelineFromImages(output_json_path)
    pipeline.process_all_pages(base_dir)

    logger.info("전체 파이프라인 실행 완료 ✅")

# 실행: python -m DB.ocr_images