# hierarchical_crop.py
# 계층적 크롭 파이프라인 클래스

import logging
import time
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import cv2
import numpy as np
from models.Detection.Model_routing_1104.run_routed_inference import RoutedInference
from models.Recognition.ocr import OCRModel
import csv

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class HierarchicalCropPipeline:
    """계층적 크롭 파이프라인: 페이지 → Section → 문제번호 및 정답 (OCR 포함)"""
    
    def __init__(self, model_dir: str):
        self.router = RoutedInference(model_dir)
        self.ocr = OCRModel()
        logger.info("HierarchicalCropPipeline 초기화 (OCR 모델 로드 완료)")
    
    def calculate_iou(self, bbox1: List[float], bbox2: List[float]) -> float:
        """두 바운딩 박스의 IoU(Intersection over Union) 계산
        
        Args:
            bbox1: [x1, y1, x2, y2]
            bbox2: [x1, y1, x2, y2]
            
        Returns:
            float: IoU 값 (0.0 ~ 1.0)
        """
        x1_1, y1_1, x2_1, y2_1 = bbox1
        x1_2, y1_2, x2_2, y2_2 = bbox2
        
        # 겹치는 영역 계산
        x1_i = max(x1_1, x1_2)
        y1_i = max(y1_1, y1_2)
        x2_i = min(x2_1, x2_2)
        y2_i = min(y2_1, y2_2)
        
        if x2_i <= x1_i or y2_i <= y1_i:
            return 0.0
        
        # Intersection 면적
        intersection = (x2_i - x1_i) * (y2_i - y1_i)
        
        # 각 박스의 면적
        area1 = (x2_1 - x1_1) * (y2_1 - y1_1)
        area2 = (x2_2 - x1_2) * (y2_2 - y1_2)
        
        # Union 면적
        union = area1 + area2 - intersection
        
        if union == 0:
            return 0.0
        
        return intersection / union
    
    def crop_page_number(self, image_path: str, detections: List[Dict], output_dir: Path) -> Tuple[Optional[str], Optional[str]]:
        """페이지 번호를 크롭하고 OCR로 인식
        
        Returns:
            Tuple[Optional[str], Optional[str]]: (크롭 이미지 경로, 인식된 페이지 번호)
        """
        image = cv2.imread(image_path)
        if image is None:
            logger.error(f"이미지 로드 실패: {image_path}")
            return None, None
        
        page_num_detections = [d for d in detections if d['class_name'] == 'page_number']
        
        if not page_num_detections:
            logger.warning(f"페이지 번호 미검출: {image_path}")
            return None, None
        
        # 신뢰도 가장 높은 것 선택
        best_det = max(page_num_detections, key=lambda x: x['confidence'])
        x1, y1, x2, y2 = map(int, best_det['bbox'])
        
        h, w = image.shape[:2]
        x1, y1 = max(0, x1), max(0, y1)
        x2, y2 = min(w, x2), min(h, y2)
        
        if x2 <= x1 or y2 <= y1:
            logger.warning(f"잘못된 페이지 번호 박스: {best_det['bbox']}")
            return None, None
        
        # 크롭 및 저장
        cropped = image[y1:y2, x1:x2]
        page_num_dir = output_dir / "page_numbers"
        page_num_dir.mkdir(parents=True, exist_ok=True)
        
        image_name = Path(image_path).stem
        save_path = page_num_dir / f"{image_name}_page_number.jpg"
        cv2.imwrite(str(save_path), cropped)
        
        # OCR로 페이지 번호 인식
        recognized_number = self.ocr.extract_number(str(save_path))
        
        logger.info(f"페이지 번호 crop 완료: {save_path}")
        logger.info(f"페이지 번호 OCR 결과: '{recognized_number}'")
        
        return str(save_path), recognized_number
    
    def process_single_crop(self, crop_image_path: str, output_dir: Path) -> Dict:
        """
        단일 crop 이미지(섹션 단위)를 입력받아 정답 번호를 추론.
        
        Args:
            crop_image_path (str): crop된 이미지 경로 (section 단위)
            output_dir (Path): 결과 저장 경로
            
        Returns:
            Dict: {'problem_number_ocr': str, 'answer_number': str, 'processing_time': float}
        """
        start_time = time.time()
        result = self.router.route_infer_single_image(crop_image_path)
        detections = result.get('detections', [])

        image = cv2.imread(crop_image_path)
        if image is None:
            logger.error(f"이미지 로드 실패: {crop_image_path}")
            return {"problem_number_ocr": None, "answer_number": None, "processing_time": 0.0}

        page_name = Path(crop_image_path).stem
        output_dir.mkdir(parents=True, exist_ok=True)

        # 문제번호 OCR (존재할 경우만)
        problem_ocr = None
        problem_num_dets = [d for d in detections if d['class_name'] == 'problem_number']
        if problem_num_dets:
            best_det = max(problem_num_dets, key=lambda x: x['confidence'])
            x1, y1, x2, y2 = map(int, best_det['bbox'])
            cropped = image[y1:y2, x1:x2]
            tmp_path = output_dir / f"{page_name}_problem_crop.jpg"
            cv2.imwrite(str(tmp_path), cropped)
            problem_ocr = self.ocr.extract_number(str(tmp_path))
            logger.info(f"문제번호 OCR 결과: {problem_ocr}")

        # answer_1과 class 1~5 IoU 기반 정답 추론
        answer_1_dets = [d for d in detections if d['class_name'] == 'answer_1']
        class_dets = [d for d in detections if d['class_name'] in ['1', '2', '3', '4', '5']]
        best_answer = None
        best_iou = 0.0

        if answer_1_dets and class_dets:
            a_bbox = answer_1_dets[0]['bbox']
            for det in class_dets:
                iou = self.calculate_iou(a_bbox, det['bbox'])
                if iou > best_iou:
                    best_iou = iou
                    best_answer = det['class_name']
            logger.info(f"최고 IoU={best_iou:.4f} → 예측 정답: {best_answer}")

        end_time = time.time()
        return {
            "problem_number_ocr": problem_ocr,
            "answer_number": best_answer,
            "processing_time": end_time - start_time
        }

# === 로깅 설정 ===
current_dir = Path(__file__).parent
log_file = current_dir / "ocr_results.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# 파일 출력 추가 (utf-8 인코딩)
file_handler = logging.FileHandler(log_file, encoding="utf-8")
file_handler.setLevel(logging.INFO)
file_formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
file_handler.setFormatter(file_formatter)
logger.addHandler(file_handler)

logger.info(f"✅ 로그 파일이 '{log_file}'로 저장됩니다.")


def main():
    """단일 crop 이미지들에 대해 정답 추론 수행"""
    total_start_time = time.time()

    # 경로 설정
    input_images_dir = current_dir / "images" / "test_images" / "1"  # crop 이미지가 있는 폴더
    output_dir = current_dir / "images" / "test_results" / "1"
    model_dir = current_dir.parent.parent / "models" / "Detection" / "Model_routing_1104"

    logger.info("=" * 60)
    logger.info("단일 Crop 이미지 정답 추론 실험 시작")
    logger.info("=" * 60)
    logger.info(f"입력 디렉토리: {input_images_dir}")
    logger.info(f"출력 디렉토리: {output_dir}")
    logger.info(f"모델 디렉토리: {model_dir}")

    # 파이프라인 초기화
    pipeline = HierarchicalCropPipeline(str(model_dir))

    # 이미지 파일 수집
    image_extensions = [".jpg", ".jpeg", ".png", ".bmp"]
    image_files = []
    for ext in image_extensions:
        image_files.extend(input_images_dir.glob(f"*{ext}"))
        image_files.extend(input_images_dir.glob(f"*{ext.upper()}"))

    image_files = sorted(image_files)
    logger.info(f"\n처리할 이미지: {len(image_files)}개")

    if not image_files:
        logger.warning(f"입력 디렉토리에 이미지가 없습니다: {input_images_dir}")
        return

    # 각 이미지 처리
    all_results = []
    for idx, image_path in enumerate(image_files):
        logger.info(f"\n\n{'#' * 60}")
        logger.info(f"[{idx + 1}/{len(image_files)}] 이미지 처리 중: {Path(image_path).name}")
        logger.info(f"{'#' * 60}")

        try:
            result = pipeline.process_single_crop(str(image_path), output_dir)
            result["image_name"] = Path(image_path).name
            all_results.append(result)
            logger.info(f"✅ 이미지 '{Path(image_path).name}' 처리 완료: {result['processing_time']:.2f}초")
        except Exception as e:
            logger.error(f"이미지 처리 실패: {image_path}")
            logger.error(f"에러: {e}", exc_info=True)
            continue

    total_end_time = time.time()
    total_processing_time = total_end_time - total_start_time

    # 요약 및 결과 저장
    print_summary(all_results, output_dir, total_processing_time)
    save_results_csv(all_results, output_dir)


def save_results_csv(all_results: list, output_dir: Path):
    """
    각 crop 이미지별 문제번호 / 정답 / 처리시간 결과 저장
    """
    csv_path = output_dir / "results_summary.csv"
    output_dir.mkdir(parents=True, exist_ok=True)

    if not all_results:
        logger.warning("⚠️ 저장할 결과가 없습니다.")
        return

    headers = ["image_name", "problem_number_ocr", "answer_number", "processing_time"]

    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=headers)
        writer.writeheader()

        for r in all_results:
            row = {h: r.get(h, "") for h in headers}
            writer.writerow(row)

    logger.info(f"\n📄 CSV 결과 저장 완료: {csv_path}")
    logger.info(f"총 {len(all_results)}개 이미지 결과가 저장되었습니다.")


def print_summary(all_results: list, output_dir: Path, total_processing_time: float):
    """전체 결과 요약 출력"""
    logger.info("\n\n" + "=" * 60)
    logger.info("전체 처리 결과 요약")
    logger.info("=" * 60)

    total_images = len(all_results)
    avg_time = (
        sum(r.get("processing_time", 0.0) for r in all_results) / total_images
        if total_images else 0.0
    )

    logger.info(f"  처리된 이미지 수: {total_images}")
    logger.info(f"  전체 처리 시간: {total_processing_time:.2f}초 ({total_processing_time / 60:.2f}분)")
    logger.info(f"  평균 처리 시간(이미지당): {avg_time:.2f}초")

    logger.info(f"\n📁 결과 CSV: {output_dir / 'results_summary.csv'}")
    logger.info(f"📁 로그 파일: {log_file}")
    logger.info("=" * 60)
    logger.info("모든 실험이 완료되었습니다.")
    logger.info("=" * 60)


if __name__ == "__main__":
    main()
