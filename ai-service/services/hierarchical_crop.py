# hierarchical_crop.py
# 계층적 크롭 파이프라인 클래스

import logging
import time
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import cv2
import numpy as np
from models.Detection.Model_routing_1104.run_routed_inference import RoutedInference
from models.recognition.ocr import OCRModel

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
        """섹션 내의 문제번호와 정답을 크롭하고 OCR 수행
        
        Returns:
            Dict: 섹션 처리 결과 (문제번호 경로 및 OCR 결과 포함)
        """
        
        # 해당 section 내부에 있는 문제번호, 정답 및 새로운 클래스(1~5) 필터링
        sx1, sy1, sx2, sy2 = section_bbox
        detections = []
        
        for det in all_detections:
            dx1, dy1, dx2, dy2 = det['bbox']
            center_x = (dx1 + dx2) / 2
            center_y = (dy1 + dy2) / 2
            
            if sx1 <= center_x <= sx2 and sy1 <= center_y <= sy2:
                if det['class_name'] in ['problem_number', 'answer_1', 'answer_2', '1', '2', '3', '4', '5']:
                    detections.append(det)
        
        # 클래스별로 신뢰도가 가장 높은 것만 선택
        filtered_detections = {}
        for det in detections:
            class_name = det['class_name']
            if class_name not in filtered_detections or det['confidence'] > filtered_detections[class_name]['confidence']:
                filtered_detections[class_name] = det
        
        detections = list(filtered_detections.values())
        
        # 원본 페이지 이미지 로드
        image = cv2.imread(original_image_path)
        if image is None:
            logger.error(f"원본 이미지 로드 실패: {original_image_path}")
            return {}
        
        section_result = {
            'section_idx': section_idx,
            'problem_numbers': [],
            'problem_numbers_ocr': [],  # OCR 결과 추가
            'answers': [],
            'class_1': [],  # 새로운 클래스 1
            'class_2': [],  # 새로운 클래스 2
            'class_3': [],  # 새로운 클래스 3
            'class_4': [],  # 새로운 클래스 4
            'class_5': [],  # 새로운 클래스 5
            'coordinate_mapping': None  # coordinate mapping 이미지 경로
        }
        
        section_output_dir = output_dir / page_name / f"section_{section_idx:02d}"
        section_output_dir.mkdir(parents=True, exist_ok=True)
        
        # answer_2 존재 여부 확인
        has_answer_2 = any(d['class_name'] == 'answer_2' for d in detections)
        
        logger.info(f"Section {section_idx}: answer_2 {'존재' if has_answer_2 else '없음'}")
        
        # 문제 번호 crop 및 OCR
        problem_num_dets = [d for d in detections if d['class_name'] == 'problem_number']
        logger.info(f"Section {section_idx}: {len(problem_num_dets)}개 문제번호 검출")
        
        for i, det in enumerate(problem_num_dets):
            x1, y1, x2, y2 = map(int, det['bbox'])
            h, w = image.shape[:2]
            x1, y1 = max(0, x1), max(0, y1)
            x2, y2 = min(w, x2), min(h, y2)
            
            if x2 <= x1 or y2 <= y1:
                continue
            
            cropped = image[y1:y2, x1:x2]
            save_path = section_output_dir / f"problem_number_{i:02d}_conf{det['confidence']:.2f}.jpg"
            cv2.imwrite(str(save_path), cropped)
            
            # OCR로 문제 번호 인식
            recognized_number = self.ocr.extract_number(str(save_path))
            
            section_result['problem_numbers'].append(str(save_path))
            section_result['problem_numbers_ocr'].append({
                'path': str(save_path),
                'number': recognized_number,
                'confidence': det['confidence']
            })
            
            logger.info(f"  문제번호 {i}: OCR='{recognized_number}' (conf={det['confidence']:.2f})")
        
        # 새로운 클래스 1~5 crop
        new_classes = ['1', '2', '3', '4', '5']
        new_class_detections = {}
        
        for new_class in new_classes:
            new_class_dets = [d for d in detections if d['class_name'] == new_class]
            
            for i, det in enumerate(new_class_dets):
                x1, y1, x2, y2 = map(int, det['bbox'])
                h, w = image.shape[:2]
                x1, y1 = max(0, x1), max(0, y1)
                x2, y2 = min(w, x2), min(h, y2)
                
                if x2 <= x1 or y2 <= y1:
                    continue
                
                cropped = image[y1:y2, x1:x2]
                save_path = section_output_dir / f"class_{new_class}_{i:02d}_conf{det['confidence']:.2f}.jpg"
                cv2.imwrite(str(save_path), cropped)
                section_result[f'class_{new_class}'].append(str(save_path))
                
                # 나중에 IoU 계산을 위해 저장
                new_class_detections[new_class] = {
                    'det': det,
                    'crop_path': str(save_path)
                }
                
                logger.info(f"  클래스 {new_class}: crop 완료 (conf={det['confidence']:.2f})")
        
        # 정답 crop (answer_1, answer_2)
        if has_answer_2:
            # answer_2가 있으면 일반적으로 크롭
            answer_classes = ['answer_1', 'answer_2']
            for ans_class in answer_classes:
                ans_dets = [d for d in detections if d['class_name'] == ans_class]
                for i, det in enumerate(ans_dets):
                    x1, y1, x2, y2 = map(int, det['bbox'])
                    h, w = image.shape[:2]
                    x1, y1 = max(0, x1), max(0, y1)
                    x2, y2 = min(w, x2), min(h, y2)
                    
                    if x2 <= x1 or y2 <= y1:
                        continue
                    
                    cropped = image[y1:y2, x1:x2]
                    save_path = section_output_dir / f"{ans_class}_{i:02d}_conf{det['confidence']:.2f}.jpg"
                    cv2.imwrite(str(save_path), cropped)
                    section_result['answers'].append(str(save_path))
                    logger.info(f"  {ans_class} crop 완료")
        else:
            # answer_2가 없으면 answer_1과 class 1~5의 IoU 계산
            answer_1_dets = [d for d in detections if d['class_name'] == 'answer_1']
            
            if answer_1_dets and new_class_detections:
                answer_1_det = answer_1_dets[0]
                answer_1_bbox = answer_1_det['bbox']
                
                # 각 class 1~5와 IoU 계산
                iou_scores = {}
                for class_name, class_data in new_class_detections.items():
                    class_bbox = class_data['det']['bbox']
                    iou = self.calculate_iou(answer_1_bbox, class_bbox)
                    iou_scores[class_name] = {
                        'iou': iou,
                        'crop_path': class_data['crop_path']
                    }
                    logger.info(f"  answer_1과 class_{class_name}의 IoU: {iou:.4f}")
                
                # 가장 높은 IoU를 가진 클래스 선택
                if iou_scores:
                    best_class = max(iou_scores.items(), key=lambda x: x[1]['iou'])
                    best_class_name = best_class[0]
                    best_iou = best_class[1]['iou']
                    best_crop_path = best_class[1]['crop_path']
                    
                    logger.info(f"  ✅ 가장 높은 IoU: class_{best_class_name} (IoU={best_iou:.4f})")
                    
                    # coordinate_mapping.jpg로 복사
                    mapping_path = section_output_dir / "coordinate_mapping.jpg"
                    import shutil
                    shutil.copy(best_crop_path, mapping_path)
                    section_result['coordinate_mapping'] = str(mapping_path)
                    logger.info(f"  coordinate_mapping.jpg 생성 완료: {mapping_path}")
            
            # answer_1 크롭
            for i, det in enumerate(answer_1_dets):
                x1, y1, x2, y2 = map(int, det['bbox'])
                h, w = image.shape[:2]
                x1, y1 = max(0, x1), max(0, y1)
                x2, y2 = min(w, x2), min(h, y2)
                
                if x2 <= x1 or y2 <= y1:
                    continue
                
                cropped = image[y1:y2, x1:x2]
                save_path = section_output_dir / f"answer_1_{i:02d}_conf{det['confidence']:.2f}.jpg"
                cv2.imwrite(str(save_path), cropped)
                section_result['answers'].append(str(save_path))
                logger.info(f"  answer_1 crop 완료")
        
        logger.info(f"Section {section_idx} 처리 완료: 문제번호 {len(section_result['problem_numbers'])}개, "
                   f"정답 {len(section_result['answers'])}개, "
                   f"새로운 클래스 {sum(len(section_result[f'class_{c}']) for c in new_classes)}개")
        return section_result
    
    def process_page(self, image_path: str, output_dir: Path) -> Dict:
        """전체 파이프라인(한 페이지 처리)
        
        Args:
            image_path: 입력 이미지 경로
            output_dir: 출력 디렉토리
            
        Returns:
            Dict: 페이지 처리 결과 (처리 시간 포함)
        """
        start_time = time.time()

        logger.info(f"\n{'='*60}")
        logger.info(f"페이지 처리 시작: {Path(image_path).name}")
        logger.info(f"{'='*60}")
        
        # 전체 페이지 추론
        result = self.router.route_infer_single_image(image_path)
        detections = result['detections']
        
        page_name = Path(image_path).stem
        page_output_dir = output_dir / page_name
        page_output_dir.mkdir(parents=True, exist_ok=True)
        
        page_result = {
            'image_path': image_path,
            'page_name': page_name,
            'page_number_path': None,
            'page_number_ocr': None,  # OCR 결과 추가
            'sections': [],
            'processing_time': 0.0  # 처리 시간 추가
        }
        
        # 1단계: 페이지 번호 crop 및 OCR
        logger.info("\n1. 페이지 번호 crop 및 OCR")
        page_num_path, page_num_ocr = self.crop_page_number(image_path, detections, page_output_dir)
        page_result['page_number_path'] = page_num_path
        page_result['page_number_ocr'] = page_num_ocr
        
        # 2단계: Section crop
        logger.info("\n2. Section crop")
        section_detections = [d for d in detections if d['class_name'] == 'section']
        section_detections = sorted(section_detections, key=lambda x: x['bbox'][1])
        
        section_info = []  # (path, idx, bbox) 저장
        image = cv2.imread(image_path)
        
        for idx, det in enumerate(section_detections):
            x1, y1, x2, y2 = map(int, det['bbox'])
            h, w = image.shape[:2]
            x1, y1 = max(0, x1), max(0, y1)
            x2, y2 = min(w, x2), min(h, y2)
            
            if x2 <= x1 or y2 <= y1:
                continue
            
            # Section 이미지 저장
            cropped = image[y1:y2, x1:x2]
            section_dir = page_output_dir / "sections"
            section_dir.mkdir(parents=True, exist_ok=True)
            save_path = section_dir / f"{page_name}_section_{idx:02d}.jpg"
            cv2.imwrite(str(save_path), cropped)
            
            section_info.append((str(save_path), idx, det['bbox']))
            logger.info(f"Section {idx} crop 완료: {save_path}")
        
        logger.info(f"총 {len(section_info)}개 Section 검출됨")
        
        # 3-4단계: 각 Section 처리 (문제번호 OCR 및 새로운 클래스 포함)
        logger.info("\n3. 각 Section에서 문제번호, 정답 및 새로운 클래스(1~5) crop (OCR 수행)")
        for section_path, section_idx, section_bbox in section_info:
            section_result = self.process_single_section(
                image_path, section_idx, page_name, output_dir,
                section_bbox, detections
            )
            page_result['sections'].append(section_result)

        end_time = time.time()
        processing_time = end_time - start_time
        page_result['processing_time'] = processing_time

        logger.info(f"\n페이지 '{page_name}' 처리 완료")
        logger.info(f"  - 페이지 번호: {page_num_ocr}")
        logger.info(f"  - Section 수: {len(section_info)}")
        logger.info(f"  - 처리 시간: {processing_time:.2f}초")
        logger.info(f"  - 출력 디렉토리: {page_output_dir}")
        
        return page_result