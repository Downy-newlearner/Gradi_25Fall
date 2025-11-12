import os
from dotenv import load_dotenv
import logging
import json
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import cv2
import numpy as np
from datetime import datetime

# --- 외부 모듈 ---
from models.Detection.Model_routing_1004.run_routed_inference import RoutedInference
from models.Recognition.ocr import OCRModel

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
class LLMDBPipeline:
    """문제집 이미지 → 이미지 저장"""

    def __init__(self, model_dir: str, groq_api_key: Optional[str] = None):
        self.router = RoutedInference(model_dir)
        self.ocr = OCRModel()
        
        # JSON 파일 초기화
        self._init_json_file()

        logger.info("LLMDBPipeline 초기화 완료")

    # -------------------------------------------------------
    # JSON 저장
    # -------------------------------------------------------
    def _init_json_file(self):
        """JSON 파일 초기화 (빈 배열로 생성)"""
        try:
            with open(self.output_json_path, 'w', encoding='utf-8') as f:
                json.dump([], f, ensure_ascii=False, indent=2)
            logger.info(f"JSON 파일 초기화 완료: {self.output_json_path}")
        except Exception as e:
            logger.error(f"JSON 파일 초기화 실패: {e}")

    def save_to_json(self, question: Dict):
        """질문을 JSON 파일에 추가"""
        try:
            # 기존 JSON 파일 읽기
            with open(self.output_json_path, 'r', encoding='utf-8') as f:
                questions_data = json.load(f)
            
            # 새로운 질문 추가
            questions_data.append(question)
            
            # 파일에 저장
            with open(self.output_json_path, 'w', encoding='utf-8') as f:
                json.dump(questions_data, f, ensure_ascii=False, indent=2)
            
            logger.info(f"JSON 저장 완료: 페이지 {question['page_number']} - 문제 {question['problem_number']}")
        except Exception as e:
            logger.error(f"JSON 저장 실패: {e}")

    # -------------------------------------------------------
    # OCR 유틸
    # -------------------------------------------------------
    def extract_text_from_image(self, image_path: str) -> str:
        """이미지에서 텍스트를 추출합니다 (한국어/영어 모두 지원)."""
        try:
            # OCRModel의 extract_text 메서드 사용
            text = self.ocr.extract_text(image_path)
            return text.strip()
        except Exception as e:
            logger.error(f"OCR 추출 실패 ({image_path}): {e}")
            return ""

    # -------------------------------------------------------
    # 페이지 번호 인식
    # -------------------------------------------------------
    def crop_page_number(self, image_path: str, detections: List[Dict], output_dir: Path) -> Tuple[Optional[str], Optional[str]]:
        image = cv2.imread(image_path)
        if image is None:
            logger.error(f"이미지 로드 실패: {image_path}")
            return None, None

        page_num_dets = [d for d in detections if d['class_name'] == 'page_number']
        if not page_num_dets:
            logger.warning(f"페이지 번호 미검출: {image_path}")
            return None, None

        best_det = max(page_num_dets, key=lambda x: x['confidence'])
        x1, y1, x2, y2 = map(int, best_det['bbox'])
        h, w = image.shape[:2]
        x1, y1, x2, y2 = max(0, x1), max(0, y1), min(w, x2), min(h, y2)
        cropped = image[y1:y2, x1:x2]

        save_dir = output_dir / "page_numbers"
        save_dir.mkdir(parents=True, exist_ok=True)
        save_path = save_dir / f"{Path(image_path).stem}_page_number.jpg"
        cv2.imwrite(str(save_path), cropped)

        logger.info(f"페이지 번호 이미지 저장: {save_path}")
        return str(save_path), None  # OCR은 나중에 수행

    # -------------------------------------------------------
    # 이미지 crop 및 저장 (이 단계에서는 OCR 미수행)
    # -------------------------------------------------------
    def crop_and_save_images(self, image_path: str, section_idx: int,
                            output_dir: Path, section_bbox: List[float], all_detections: List[Dict]) -> List[Dict]:
        """이미지를 crop하고 저장만 수행 (OCR 미수행)"""
        image = cv2.imread(image_path)
        if image is None:
            return []

        sx1, sy1, sx2, sy2 = section_bbox
        section_output = output_dir / f"section_{section_idx:02d}"
        section_output.mkdir(parents=True, exist_ok=True)

        detections = [d for d in all_detections if sx1 <= (d['bbox'][0]+d['bbox'][2])/2 <= sx2
                      and sy1 <= (d['bbox'][1]+d['bbox'][3])/2 <= sy2]

        problems = [d for d in detections if d['class_name'] == 'problem_number']
        results = []

        for idx, prob_det in enumerate(problems):
            # 문제 번호 이미지 저장
            x1, y1, x2, y2 = map(int, prob_det['bbox'])
            cropped = image[y1:y2, x1:x2]
            prob_num_path = section_output / f"prob_{idx:02d}_number.jpg"
            cv2.imwrite(str(prob_num_path), cropped)

            result = {
                "page_number": None,  # OCR 단계에서 채움
                "problem_number": None,  # OCR 후 채움
                "korean_content": None,
                "english_content": None,
                "answer_option": None,
                "crop_paths": {"problem_number": str(prob_num_path)}
            }

            # --- 영어 지문 이미지 저장 ---
            eng_dets = [d for d in detections if d['class_name'] == 'english_content']
            if eng_dets:
                ed = eng_dets[0]
                x1, y1, x2, y2 = map(int, ed['bbox'])
                cropped = image[y1:y2, x1:x2]
                eng_path = section_output / f"prob_{idx:02d}_english_content.jpg"
                cv2.imwrite(str(eng_path), cropped)
                result["crop_paths"]["english_content"] = str(eng_path)

            # --- 한국어 지문 이미지 저장 ---
            kor_dets = [d for d in detections if d['class_name'] == 'korean_content']
            if kor_dets:
                kd = kor_dets[0]
                x1, y1, x2, y2 = map(int, kd['bbox'])
                cropped = image[y1:y2, x1:x2]
                kor_path = section_output / f"prob_{idx:02d}_korean_content.jpg"
                cv2.imwrite(str(kor_path), cropped)
                result["crop_paths"]["korean_content"] = str(kor_path)

            # --- 선택지 이미지 저장 ---
            answer_dets = [d for d in detections if d['class_name'] in ['answer_option', 'answer_1', 'answer_2']]
            answer_dets = sorted(answer_dets, key=lambda x: x['class_name'])
            for a_idx, a_det in enumerate(answer_dets):
                x1, y1, x2, y2 = map(int, a_det['bbox'])
                cropped = image[y1:y2, x1:x2]
                a_path = section_output / f"prob_{idx:02d}_{a_det['class_name']}.jpg"
                cv2.imwrite(str(a_path), cropped)
                result["crop_paths"][a_det['class_name']] = str(a_path)

            results.append(result)
            logger.info(f"문제 {idx:02d} 이미지 저장 완료")

        return results

    # -------------------------------------------------------
    # OCR 인식 (저장된 이미지에 대해 수행)
    # -------------------------------------------------------
    def perform_ocr_on_saved_images(self, question: Dict):
        """저장된 이미지에 대해 OCR 수행"""
        crop_paths = question.get("crop_paths", {})

        # 문제 번호 OCR
        if "problem_number" in crop_paths:
            prob_num = self.ocr.extract_number(crop_paths["problem_number"])
            question["problem_number"] = prob_num
            logger.info(f"문제 번호 OCR 완료: {prob_num}")

        # 영어 지문 OCR
        if "english_content" in crop_paths:
            eng_text = self.extract_text_from_image(crop_paths["english_content"])
            question["english_content"] = eng_text
            logger.info(f"영어 지문 OCR 완료")

        # 한국어 지문 OCR
        if "korean_content" in crop_paths:
            kor_text = self.extract_text_from_image(crop_paths["korean_content"])
            question["korean_content"] = kor_text
            logger.info(f"한국어 지문 OCR 완료")

        # 선택지 OCR
        answer_list = []
        for key in sorted(crop_paths.keys()):
            if key in ['answer_option', 'answer_1', 'answer_2']:
                ans_text = self.extract_text_from_image(crop_paths[key])
                answer_list.append(ans_text)
        
        if answer_list:
            question["answer_option"] = json.dumps(answer_list, ensure_ascii=False)
            logger.info(f"선택지 OCR 완료 ({len(answer_list)}개)")

        return question

    # -------------------------------------------------------
    # 페이지 단위 처리 - 1단계: 이미지 Crop
    # -------------------------------------------------------
    def crop_page(self, image_path: str, output_dir: Path):
        """이미지를 crop하여 output 폴더에 저장"""
        try:
            result = self.router.route_infer_single_image(image_path)
            detections = result.get("detections", [])

            page_output = output_dir / Path(image_path).stem
            page_output.mkdir(parents=True, exist_ok=True)

            page_num_path, _ = self.crop_page_number(image_path, detections, page_output)
            if not page_num_path:
                logger.error(f"페이지 번호 이미지 저장 실패: {image_path}")
                return

            section_dets = sorted(
                [d for d in detections if d["class_name"] == "section"],
                key=lambda x: x["bbox"][1]
            )

            total_questions = 0
            for s_idx, s_det in enumerate(section_dets):
                questions = self.crop_and_save_images(image_path, s_idx, page_output, s_det["bbox"], detections)
                total_questions += len(questions)
            
            logger.info(f"페이지 {Path(image_path).stem}: {total_questions}개 문제 이미지 저장 완료")
        except Exception as e:
            logger.error(f"페이지 Crop 중 오류 발생 ({image_path}): {e}")

    def process_multiple_pages(self, images_dir: str, output_dir: str):
        """전체 파이프라인 실행"""
        # Step 1: 모든 이미지 Crop
        logger.info("=== Step 1: 모든 이미지 Crop 시작 ===")
        images = sorted(Path(images_dir).glob("*.jpg")) + sorted(Path(images_dir).glob("*.png"))
        
        for img in images:
            logger.info(f"Crop 처리 중: {img.name}")
            self.crop_page(str(img), Path(output_dir))
        
        logger.info(f"=== Step 1 완료: Crop 저장 ===")

# -----------------------------------------------------------
# 실행 예시
# -----------------------------------------------------------
if __name__ == "__main__":
    import os

    model_dir = "./models/Detection/Model_routing_1004"
    images_dir = "./DB/images/database1"
    output_dir = "./DB/output/database1"

    pipeline = LLMDBPipeline(model_dir)
    pipeline.process_multiple_pages(images_dir, output_dir)

    logger.info("전체 파이프라인 실행 완료 ✅")