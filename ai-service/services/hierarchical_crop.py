# hierarchical_crop.py
# 계층적 크롭 파이프라인 클래스

import logging
import time
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import cv2
import numpy as np
from models.Detection.Model_routing_1111.infer_and_evaluate import RoutedInference
from models.Recognition.ocr import OCRModel

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
    
    def process_single_section(self, original_image_path: str, section_idx: int, 
                            page_name: str, output_dir: Path, 
                            section_bbox: List[float], all_detections: List[Dict]) -> Dict:
        """섹션 내의 문제번호와 정답을 추론 (IoU 기반 정답 번호 결정)
        
        Returns:
            Dict: {'section_idx', 'problem_number_ocr', 'answer_number'}
        """
        sx1, sy1, sx2, sy2 = section_bbox
        section_dets = []

        for det in all_detections:
            dx1, dy1, dx2, dy2 = det['bbox']
            cx, cy = (dx1 + dx2) / 2, (dy1 + dy2) / 2
            if sx1 <= cx <= sx2 and sy1 <= cy <= sy2:
                if det['class_name'] in ['problem_number', 'answer_1', '1', '2', '3', '4', '5']:
                    section_dets.append(det)

        # 문제번호 OCR (여기만 crop + OCR 수행)
        image = cv2.imread(original_image_path)
        problem_ocr = None
        problem_num_dets = [d for d in section_dets if d['class_name'] == 'problem_number']
        if problem_num_dets:
            best_det = max(problem_num_dets, key=lambda x: x['confidence'])
            x1, y1, x2, y2 = map(int, best_det['bbox'])
            cropped = image[y1:y2, x1:x2]
            tmp_path = f"/tmp/problem_tmp_{page_name}_{section_idx}.jpg"
            cv2.imwrite(tmp_path, cropped)
            problem_ocr = self.ocr.extract_number(tmp_path)

        # answer_1과 class 1~5의 IoU 계산
        answer_1_dets = [d for d in section_dets if d['class_name'] == 'answer_1']
        class_dets = [d for d in section_dets if d['class_name'] in ['1', '2', '3', '4', '5']]
        best_answer = None
        best_iou = 0.0

        if answer_1_dets and class_dets:
            a_bbox = answer_1_dets[0]['bbox']
            for det in class_dets:
                iou = self.calculate_iou(a_bbox, det['bbox'])
                if iou > best_iou:
                    best_iou = iou
                    best_answer = det['class_name']

        return {
            'section_idx': section_idx,
            'problem_number_ocr': problem_ocr,
            'answer_number': best_answer
        }

    def process_page(self, image_path: str, output_dir: Path) -> Dict:
        """3-4단계만 수행: 각 Section에서 문제번호 OCR + 정답 번호 추론 및 CSV 저장"""
        start_time = time.time()
        result = self.router.route_infer_single_image(image_path)
        detections = result['detections']

        page_name = Path(image_path).stem
        page_output_dir = output_dir / page_name
        page_output_dir.mkdir(parents=True, exist_ok=True)

        # 페이지 번호 OCR
        page_num_path, page_num_ocr = self.crop_page_number(image_path, detections, page_output_dir)

        # Section 영역 검출
        section_detections = [d for d in detections if d['class_name'] == 'section']
        section_detections = sorted(section_detections, key=lambda x: x['bbox'][1])

        page_result = []
        for idx, det in enumerate(section_detections):
            section_bbox = det['bbox']
            section_result = self.process_single_section(
                image_path, idx, page_name, output_dir, section_bbox, detections
            )
            page_result.append(section_result)

        # 결과 CSV 저장 (문제번호 포함)
        csv_path = page_output_dir / f"{page_name}_results.csv"
        import csv
        with open(csv_path, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(["image_name", "page_number", "problem_number", "answer_number"])
            for r in page_result:
                writer.writerow([
                    page_name,
                    page_num_ocr if page_num_ocr else "",
                    r.get('problem_number_ocr', ""),
                    r.get('answer_number', "")
                ])

        logger.info(f"결과 CSV 저장 완료: {csv_path}")

        end_time = time.time()
        return {
            "image_path": image_path,
            "page_name": page_name,
            "page_number_ocr": page_num_ocr,
            "results_csv": str(csv_path),
            "sections": page_result,
            "processing_time": end_time - start_time
        }
