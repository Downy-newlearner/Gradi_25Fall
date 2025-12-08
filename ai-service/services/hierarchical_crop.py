# services/hierarchical_crop.py
import logging
import time
import os
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import cv2
import numpy as np
import torch
import torch.nn as nn
from torchvision import transforms
from models.Detection.legacy.Model_routing_1104.run_routed_inference import RoutedInference as RoutedInference_1104
from models.Detection.legacy.Model_routing_1004.run_routed_inference import RoutedInference as RoutedInference_1004
from models.Recognition.resnetClassifier import ResNetClassifier
from models.Recognition.ocr import OCRModel

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class HierarchicalCropPipeline:
    """계층적 크롭 파이프라인: 페이지 → Section → 문제번호 및 정답 (answer_2 우선, answer_1 fallback)"""
    
    def __init__(self, model_dir_1104: str, model_dir_1004: str, 
                 section_padding: int = 50,
                 answer_key_path: Optional[str] = None,
                 resnet_answer_1_path: Optional[str] = None,
                 resnet_answer_2_path: Optional[str] = None):
        """
        Args:
            model_dir_1104: 1104 모델 경로
            model_dir_1004: 1004 모델 경로
            section_padding: Section crop 시 추가할 여백 (픽셀). 기본값 50
            answer_key_path: 답지 파일 경로 (txt 파일)
            resnet_answer_1_path: answer_1용 ResNet 모델 경로 (.pth 파일)
            resnet_answer_2_path: answer_2용 ResNet 모델 경로 (.pth 파일)
        """
        self.router_1104 = RoutedInference_1104(model_dir_1104)  # 답안 추론용
        self.router_1004 = RoutedInference_1004(model_dir_1004)  # 크롭용 (페이지번호, 문제번호, section)
        self.ocr = OCRModel()
        self.section_padding = section_padding
        
        # ✨ answer_1과 answer_2용 ResNet 모델 초기화
        self.resnet_answer_1 = None
        self.resnet_answer_2 = None
        
        # answer_1 ResNet 로드
        if resnet_answer_1_path and os.path.exists(resnet_answer_1_path):
            try:
                self.resnet_answer_1 = ResNetClassifier(resnet_answer_1_path, model_type='answer_1')
                logger.info("✅ answer_1 ResNet 분류 모델 로드 성공")
            except Exception as e:
                logger.error(f"❌ answer_1 ResNet 모델 로드 실패: {e}")
                logger.warning("answer_1 ResNet 분류를 사용할 수 없습니다.")
        else:
            if resnet_answer_1_path:
                logger.warning(f"answer_1 ResNet 모델 파일을 찾을 수 없습니다: {resnet_answer_1_path}")
            logger.info("answer_1 ResNet 분류 없이 실행됩니다.")
        
        # answer_2 ResNet 로드
        if resnet_answer_2_path and os.path.exists(resnet_answer_2_path):
            try:
                self.resnet_answer_2 = ResNetClassifier(resnet_answer_2_path, model_type='answer_2')
                logger.info("✅ answer_2 ResNet 분류 모델 로드 성공")
            except Exception as e:
                logger.error(f"❌ answer_2 ResNet 모델 로드 실패: {e}")
                logger.warning("answer_2 ResNet 분류를 사용할 수 없습니다.")
        else:
            if resnet_answer_2_path:
                logger.warning(f"answer_2 ResNet 모델 파일을 찾을 수 없습니다: {resnet_answer_2_path}")
            logger.info("answer_2 ResNet 분류 없이 실행됩니다.")
        
        # 답지 로드
        self.answer_key = self._load_answer_key(answer_key_path) if answer_key_path else None
        
        logger.info("HierarchicalCropPipeline 초기화 (두 개의 모델 + OCR 모델 로드 완료)")
        logger.info("  - 1104 모델: 답안 추론용 (answer_1, answer_2 검출)")
        logger.info("  - 1004 모델: 페이지번호, 문제번호, section 크롭용")
        logger.info(f"  - Section padding: {section_padding}px")
        logger.info(f"  - answer_1 ResNet: {'사용 가능' if self.resnet_answer_1 else '사용 불가'}")
        logger.info(f"  - answer_2 ResNet: {'사용 가능' if self.resnet_answer_2 else '사용 불가'}")
        if self.answer_key:
            logger.info(f"  - 답지 로드 완료: {len(self.answer_key)}개 페이지")
    
    def _normalize_number(self, number_str: Optional[str]) -> Optional[str]:
        """
        숫자 문자열 정규화: 앞의 0 제거 (01 -> 1, 001 -> 1)
        
        Args:
            number_str: OCR로 인식된 숫자 문자열
            
        Returns:
            정규화된 숫자 문자열
        """
        if number_str is None:
            return None
        
        number_str = number_str.strip()
        
        if not number_str:
            return None
        
        # 숫자로만 이루어진 경우 앞의 0 제거
        if number_str.isdigit():
            return str(int(number_str))  # "01" -> "1", "001" -> "1"
        
        return number_str
    
    def _load_answer_key(self, answer_key_path: str) -> Dict[str, List[Dict]]:
        """답지 파일 로드
        
        파일 형식: 페이지번호, 문제번호, 정답
        예: 1, 1, 3
        
        Returns:
            Dict[str, List[Dict]]: {페이지번호: [{'problem': 문제번호, 'answer': 정답}, ...]}
        """
        answer_key = {}
        try:
            with open(answer_key_path, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    
                    parts = [p.strip() for p in line.split(',')]
                    if len(parts) >= 3:
                        page_num = self._normalize_number(parts[0])
                        problem_num = self._normalize_number(parts[1])
                        answer = parts[2]
                        
                        if page_num not in answer_key:
                            answer_key[page_num] = []
                        
                        answer_key[page_num].append({
                            'problem': problem_num,
                            'answer': answer
                        })
            
            logger.info(f"답지 로드 완료: {answer_key_path}")
            for page, problems in answer_key.items():
                logger.info(f"  페이지 {page}: {len(problems)}개 문제")
        
        except Exception as e:
            logger.error(f"답지 로드 실패: {e}")
            return {}
        
        return answer_key
    
    def is_valid_page(self, page_number: Optional[str]) -> bool:
        """페이지 번호가 답지에 있는지 확인"""
        if self.answer_key is None:
            return True
        
        if page_number is None:
            logger.warning("페이지 번호를 인식하지 못했습니다. 건너뜁니다.")
            return False
        
        page_number_normalized = self._normalize_number(page_number)
        is_valid = page_number_normalized in self.answer_key
        
        if not is_valid:
            logger.warning(f"페이지 {page_number_normalized}는 답지에 없습니다. 건너뜁니다.")
        else:
            logger.info(f"페이지 {page_number_normalized}는 답지에 있습니다. 처리를 계속합니다.")
        
        return is_valid
    
    def get_missing_problem_number(self, page_number: Optional[str], 
                                   recognized_numbers: set) -> Optional[str]:
        """답지 기반으로 페이지에서 누락된 문제 번호 중 가장 작은 것을 반환"""
        if self.answer_key is None or page_number is None:
            return None
        
        page_number_normalized = self._normalize_number(page_number)
        
        if page_number_normalized not in self.answer_key:
            return None
        
        expected_problems = {item['problem'] for item in self.answer_key[page_number_normalized]}
        # recognized_numbers도 정규화하여 비교
        recognized_normalized = {self._normalize_number(n) for n in recognized_numbers if n}
        missing = expected_problems - recognized_normalized
        
        if not missing:
            return None
        
        try:
            missing_sorted = sorted(missing, key=lambda x: int(x) if x and x.isdigit() else float('inf'))
            smallest_missing = missing_sorted[0]
            logger.info(f"📋 누락된 문제 번호 중 가장 작은 값: {smallest_missing}")
            return smallest_missing
        except Exception as e:
            logger.error(f"누락된 문제 번호 정렬 실패: {e}")
            return None
    
    def calculate_iou(self, bbox1: List[float], bbox2: List[float]) -> float:
        """두 바운딩 박스의 IoU 계산"""
        x1_1, y1_1, x2_1, y2_1 = bbox1
        x1_2, y1_2, x2_2, y2_2 = bbox2
        
        x1_i = max(x1_1, x1_2)
        y1_i = max(y1_1, y1_2)
        x2_i = min(x2_1, x2_2)
        y2_i = min(y2_1, y2_2)
        
        if x2_i <= x1_i or y2_i <= y1_i:
            return 0.0
        
        intersection = (x2_i - x1_i) * (y2_i - y1_i)
        area1 = (x2_1 - x1_1) * (y2_1 - y1_1)
        area2 = (x2_2 - x1_2) * (y2_2 - y1_2)
        union = area1 + area2 - intersection
        
        if union == 0:
            return 0.0
        
        return intersection / union
    
    def expand_bbox_with_padding(self, bbox: List[float], padding: int, img_width: int, img_height: int) -> List[int]:
        """바운딩 박스에 padding을 추가"""
        x1, y1, x2, y2 = bbox
        
        x1_expanded = max(0, int(x1 - padding))
        y1_expanded = max(0, int(y1 - padding))
        x2_expanded = min(img_width, int(x2 + padding))
        y2_expanded = min(img_height, int(y2 + padding))
        
        return [x1_expanded, y1_expanded, x2_expanded, y2_expanded]
    
    def is_bbox_near_section_boundary(self, bbox: List[float], section_bbox: List[float], threshold: int = 30) -> bool:
        """문제번호 박스가 section 경계 근처에 있는지 확인"""
        bx1, by1, bx2, by2 = bbox
        sx1, sy1, sx2, sy2 = section_bbox
        
        dist_top = abs(by1 - sy1)
        dist_bottom = abs(by2 - sy2)
        dist_left = abs(bx1 - sx1)
        dist_right = abs(bx2 - sx2)
        
        return min(dist_top, dist_bottom, dist_left, dist_right) < threshold
    
    def crop_page_number(self, image_path: str, detections_1004: List[Dict], output_dir: Path) -> Tuple[Optional[str], Optional[str]]:
        """페이지 번호를 크롭하고 OCR로 인식 (이미지 저장 없이)"""
        image = cv2.imread(image_path)
        if image is None:
            logger.error(f"이미지 로드 실패: {image_path}")
            return None, None
        
        page_num_detections = [d for d in detections_1004 if d['class_name'] == 'page_number']
        
        if not page_num_detections:
            logger.warning(f"페이지 번호 미검출: {image_path}")
            return None, None
        
        best_det = max(page_num_detections, key=lambda x: x['confidence'])
        x1, y1, x2, y2 = map(int, best_det['bbox'])
        
        h, w = image.shape[:2]
        x1, y1 = max(0, x1), max(0, y1)
        x2, y2 = min(w, x2), min(h, y2)
        
        if x2 <= x1 or y2 <= y1:
            logger.warning(f"잘못된 페이지 번호 박스: {best_det['bbox']}")
            return None, None
        
        cropped = image[y1:y2, x1:x2]
        
        import tempfile
        with tempfile.NamedTemporaryFile(suffix='.jpg', delete=True) as tmp:
            cv2.imwrite(tmp.name, cropped)
            recognized_number = self.ocr.extract_number(tmp.name)
            # 앞의 0 제거
            recognized_number = self._normalize_number(recognized_number)
        
        return None, recognized_number
    
    def classify_answer_with_resnet(self, answer_crop_path: str, section_idx: int, 
                                   answer_type: str = "answer_1") -> Tuple[Optional[str], float, bool]:
        """answer crop 이미지를 해당 타입의 ResNet으로 분류"""
        if answer_type == 'answer_2':
            resnet_model = self.resnet_answer_2
        else:
            resnet_model = self.resnet_answer_1
        
        if resnet_model is None:
            logger.warning(f"Section {section_idx}: {answer_type} ResNet 모델이 없어 분류를 사용할 수 없습니다.")
            return None, 0.0, True
        
        if not os.path.exists(answer_crop_path):
            logger.error(f"Section {section_idx}: {answer_type} 이미지가 없어 ResNet을 사용할 수 없습니다: {answer_crop_path}")
            return None, 0.0, True
        
        try:
            answer, confidence = resnet_model.predict(answer_crop_path)
            
            if answer is None:
                logger.warning(f"Section {section_idx}: {answer_type} ResNet 예측 실패")
                return None, 0.0, True
            
            return answer, confidence, False
            
        except Exception as e:
            logger.error(f"Section {section_idx}: {answer_type} ResNet 예측 중 예외 발생: {e}")
            return None, 0.0, True
    
    def _construct_section_path(self, output_dir: Path, page_number: str, problem_number: str) -> Path:
        """
        Section 이미지 저장 경로 생성
        
        형식: {output_dir}/{page_number}/{problem_number}/{page_number}_{problem_number}_section.jpg
        
        Args:
            output_dir: 기본 출력 디렉토리
            page_number: 페이지 번호
            problem_number: 문제 번호
            
        Returns:
            Path: 전체 파일 경로
        """
        # 디렉토리 경로: {output_dir}/{page_number}/{problem_number}/
        section_dir = output_dir / str(page_number) / str(problem_number)
        section_dir.mkdir(parents=True, exist_ok=True)
        
        # 파일명: {page_number}_{problem_number}_section.jpg
        filename = f"{page_number}_{problem_number}_section.jpg"
        
        return section_dir / filename
    
    def process_single_section(self, original_image_path: str, section_idx: int, 
                            page_name: str, output_dir: Path, 
                            section_bbox: List[float], detections_1004: List[Dict],
                            detections_1104: List[Dict], page_number_ocr: Optional[str] = None,
                            recognized_problem_numbers: Optional[set] = None) -> Dict:
        """섹션 내의 문제번호와 정답을 추론
        
        ✨ Section 이미지 저장 경로:
        {output_dir}/{page_number}/{problem_number}/{page_number}_{problem_number}_section.jpg
        
        Args:
            original_image_path: 원본 이미지 경로
            section_idx: Section 인덱스
            page_name: 페이지 이름
            output_dir: 출력 디렉토리
            section_bbox: Section 바운딩 박스
            detections_1004: 1004 모델 검출 결과
            detections_1104: 1104 모델 검출 결과
            page_number_ocr: 페이지 번호 (OCR 인식 결과)
            recognized_problem_numbers: 이미 인식된 문제 번호들의 집합
        
        Returns:
            Dict: 처리 결과
        """
        if recognized_problem_numbers is None:
            recognized_problem_numbers = set()
        
        sx1, sy1, sx2, sy2 = section_bbox
        image = cv2.imread(original_image_path)
        h, w = image.shape[:2]
        
        # Section bbox 유효성 검사
        if sx2 <= sx1 or sy2 <= sy1:
            logger.error(f"❌ Section {section_idx} CROP 실패: 잘못된 bbox")
            return self._create_failure_result(section_idx, 'invalid_bbox', section_bbox, w, h)
        
        # Section 이미지 크롭 시 padding 추가
        expanded_section_bbox = self.expand_bbox_with_padding(
            [sx1, sy1, sx2, sy2], 
            self.section_padding, 
            w, h
        )
        sx1_exp, sy1_exp, sx2_exp, sy2_exp = expanded_section_bbox
        
        if sx2_exp <= sx1_exp or sy2_exp <= sy1_exp:
            logger.error(f"❌ Section {section_idx} CROP 실패: 잘못된 확장 bbox")
            return self._create_failure_result(section_idx, 'invalid_expanded_bbox', section_bbox, w, h, expanded_section_bbox)
        
        # Section 이미지 크롭
        try:
            section_cropped = image[sy1_exp:sy2_exp, sx1_exp:sx2_exp]
            crop_h, crop_w = section_cropped.shape[:2]
            
            if crop_h == 0 or crop_w == 0:
                logger.error(f"❌ Section {section_idx} CROP 실패: 크롭된 이미지 크기가 0")
                return self._create_failure_result(section_idx, 'zero_size_crop', section_bbox, w, h, expanded_section_bbox)
                
        except Exception as e:
            logger.error(f"❌ Section {section_idx} CROP 실패: {e}")
            return self._create_failure_result(section_idx, f'exception: {str(e)}', section_bbox, w, h)
        
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        # 문제번호 OCR 먼저 수행 (파일 저장 경로 결정에 필요)
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        # 1004 모델에서 문제번호 검출
        section_dets_1004 = []
        for det in detections_1004:
            dx1, dy1, dx2, dy2 = det['bbox']
            cx, cy = (dx1 + dx2) / 2, (dy1 + dy2) / 2
            if sx1_exp <= cx <= sx2_exp and sy1_exp <= cy <= sy2_exp:
                if det['class_name'] == 'problem_number':
                    section_dets_1004.append(det)
        
        # 문제번호 OCR
        problem_ocr = None
        problem_ocr_override = False
        
        if section_dets_1004:
            if len(section_dets_1004) == 2:
                logger.warning(f"⚠️ Section {section_idx}: 문제번호 2개 검출됨!")
                missing_number = self.get_missing_problem_number(page_number_ocr, recognized_problem_numbers)
                
                if missing_number:
                    problem_ocr = missing_number
                    problem_ocr_override = True
                    logger.info(f"✅ Section {section_idx}: 누락된 문제 번호 할당 → {problem_ocr}")
                else:
                    best_det = max(section_dets_1004, key=lambda x: x['confidence'])
            else:
                best_det = max(section_dets_1004, key=lambda x: x['confidence'])
            
            if not problem_ocr_override:
                x1, y1, x2, y2 = map(int, best_det['bbox'])
                x1, y1 = max(0, x1), max(0, y1)
                x2, y2 = min(w, x2), min(h, y2)
                
                if x2 > x1 and y2 > y1:
                    cropped = image[y1:y2, x1:x2]
                    import tempfile
                    with tempfile.NamedTemporaryFile(suffix='.jpg', delete=True) as tmp:
                        cv2.imwrite(tmp.name, cropped)
                        problem_ocr = self.ocr.extract_number(tmp.name)
                        # 앞의 0 제거 (01 -> 1, 001 -> 1)
                        problem_ocr = self._normalize_number(problem_ocr)
        else:
            logger.warning(f"Section {section_idx}: 문제번호 미검출")
        
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        # Section 이미지 저장 (올바른 경로로)
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        section_crop_path = None
        
        # 페이지 번호와 문제 번호가 있어야 올바른 경로에 저장 가능
        if page_number_ocr and problem_ocr:
            section_crop_path = self._construct_section_path(output_dir, page_number_ocr, problem_ocr)
            
            try:
                write_success = cv2.imwrite(str(section_crop_path), section_cropped)
                
                if not write_success or not section_crop_path.exists():
                    logger.error(f"❌ Section {section_idx} 파일 저장 실패: {section_crop_path}")
                    section_crop_path = None
                else:
                    logger.info(f"✅ Section 이미지 저장: {section_crop_path}")
            except Exception as e:
                logger.error(f"❌ Section {section_idx} 파일 저장 중 오류: {e}")
                section_crop_path = None
        else:
            # 페이지 번호나 문제 번호가 없으면 임시 경로에 저장
            fallback_dir = output_dir / "unknown"
            fallback_dir.mkdir(parents=True, exist_ok=True)
            fallback_path = fallback_dir / f"section_{section_idx:02d}.jpg"
            
            try:
                cv2.imwrite(str(fallback_path), section_cropped)
                section_crop_path = fallback_path
                logger.warning(f"⚠️ Section {section_idx}: 페이지/문제번호 미확인, 임시 경로에 저장: {fallback_path}")
            except Exception as e:
                logger.error(f"❌ Section {section_idx} fallback 저장 실패: {e}")
        
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        # 1104 모델에서 answer_1, answer_2, 숫자(1-5) 검출
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        section_dets_1104 = []
        for det in detections_1104:
            dx1, dy1, dx2, dy2 = det['bbox']
            cx, cy = (dx1 + dx2) / 2, (dy1 + dy2) / 2
            if sx1_exp <= cx <= sx2_exp and sy1_exp <= cy <= sy2_exp:
                if det['class_name'] in ['answer_1', 'answer_2', '1', '2', '3', '4', '5']:
                    section_dets_1104.append(det)

        answer_1_dets = [d for d in section_dets_1104 if d['class_name'] == 'answer_1']
        answer_2_dets = [d for d in section_dets_1104 if d['class_name'] == 'answer_2']

        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        # 답안 인식 로직
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        best_answer = None
        used_resnet = False
        resnet_confidence = 0.0
        resnet_failed = False
        answer_source = None
        yolo_iou_verification = None

        # 1단계: YOLO로 answer_2 검출 여부 확인
        if answer_2_dets:
            best_det = max(answer_2_dets, key=lambda x: x['confidence'])
            answer_2_bbox = best_det['bbox']
            x1, y1, x2, y2 = map(int, answer_2_bbox)
            x1, y1 = max(0, x1), max(0, y1)
            x2, y2 = min(w, x2), min(h, y2)
            
            if x2 > x1 and y2 > y1:
                cropped_answer_2 = image[y1:y2, x1:x2]
                
                import tempfile
                with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as tmp:
                    cv2.imwrite(tmp.name, cropped_answer_2)
                    answer_2_temp_path = tmp.name
                
                try:
                    answer, conf, failed = self.classify_answer_with_resnet(answer_2_temp_path, section_idx, "answer_2")
                    
                    if not failed and answer is not None:
                        best_answer = answer
                        resnet_confidence = conf
                        used_resnet = True
                        answer_source = 'answer_2_resnet'
                    else:
                        resnet_failed = True
                        used_resnet = True
                        answer_source = 'answer_2_failed'
                finally:
                    os.unlink(answer_2_temp_path)
            else:
                answer_source = 'answer_2_invalid_bbox'
        
        # 2단계: answer_2가 없거나 실패 → answer_1 처리
        if best_answer is None:
            if answer_1_dets:
                best_det = max(answer_1_dets, key=lambda x: x['confidence'])
                answer_1_bbox = best_det['bbox']
                x1, y1, x2, y2 = map(int, answer_1_bbox)
                x1, y1 = max(0, x1), max(0, y1)
                x2, y2 = min(w, x2), min(h, y2)
                
                if x2 > x1 and y2 > y1:
                    cropped_answer_1 = image[y1:y2, x1:x2]
                    
                    import tempfile
                    with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as tmp:
                        cv2.imwrite(tmp.name, cropped_answer_1)
                        answer_1_temp_path = tmp.name
                    
                    try:
                        answer, conf, failed = self.classify_answer_with_resnet(answer_1_temp_path, section_idx, "answer_1")
                        
                        if not failed and answer is not None:
                            # YOLO IoU로 검증
                            number_dets = [d for d in section_dets_1104 if d['class_name'] in ['1', '2', '3', '4', '5']]
                            
                            if number_dets:
                                iou_results = []
                                for det in number_dets:
                                    iou = self.calculate_iou(answer_1_bbox, det['bbox'])
                                    iou_results.append({
                                        'number': det['class_name'],
                                        'iou': iou,
                                        'confidence': det['confidence']
                                    })
                                
                                best_iou_result = max(iou_results, key=lambda x: x['iou'])
                                yolo_best_number = best_iou_result['number']
                                yolo_best_iou = best_iou_result['iou']
                                
                                yolo_iou_verification = {
                                    'yolo_best': yolo_best_number,
                                    'yolo_iou': yolo_best_iou,
                                    'resnet_pred': answer,
                                    'resnet_conf': conf,
                                    'all_ious': iou_results
                                }
                                
                                if answer != yolo_best_number:
                                    logger.warning(f"⚠️ Section {section_idx}: ResNet({answer}) ≠ YOLO IoU({yolo_best_number})")
                                    
                                    if conf < 0.70 and yolo_best_iou > 0.3:
                                        best_answer = yolo_best_number
                                        answer_source = 'answer_1_yolo'
                                    else:
                                        best_answer = answer
                                        answer_source = 'answer_1_resnet'
                                else:
                                    best_answer = answer
                                    answer_source = 'answer_1_resnet'
                            else:
                                best_answer = answer
                                answer_source = 'answer_1_resnet'
                            
                            resnet_confidence = conf
                            used_resnet = True
                            resnet_failed = False
                        else:
                            resnet_failed = True
                            used_resnet = True
                            answer_source = 'answer_1_failed'
                    finally:
                        os.unlink(answer_1_temp_path)
                else:
                    resnet_failed = True
                    answer_source = 'answer_1_invalid_bbox'
            else:
                resnet_failed = True
                answer_source = 'no_answer_detected'

        # 정답 여부 판단
        correction = None
        if self.answer_key and page_number_ocr and problem_ocr and best_answer:
            page_number_normalized = self._normalize_number(page_number_ocr)
            if page_number_normalized in self.answer_key:
                for item in self.answer_key[page_number_normalized]:
                    if item['problem'] == problem_ocr:
                        correct_answer = item['answer']
                        correction = (best_answer == correct_answer)
                        break

        return {
            'section_idx': section_idx,
            'problem_number_ocr': problem_ocr,
            'problem_number_override': problem_ocr_override,
            'answer_number': best_answer,
            'correction': correction,
            'section_crop_path': str(section_crop_path) if section_crop_path else None,
            'problem_crop_path': None,
            'answer_1_crop_path': None,
            'answer_2_crop_path': None,
            'crop_success': section_crop_path is not None,
            'is_boundary_issue': len(section_dets_1004) > 0 and any(
                self.is_bbox_near_section_boundary(d['bbox'], [sx1, sy1, sx2, sy2]) 
                for d in section_dets_1004
            ),
            'used_resnet': used_resnet,
            'resnet_confidence': resnet_confidence,
            'resnet_failed': resnet_failed,
            'answer_source': answer_source,
            'yolo_iou_verification': yolo_iou_verification,
            'debug_info': {
                'original_bbox': section_bbox,
                'expanded_bbox': expanded_section_bbox,
                'crop_size': (crop_w, crop_h),
                'image_size': (w, h),
                'answer_1_count': len(answer_1_dets),
                'answer_2_count': len(answer_2_dets),
                'problem_number_count': len(section_dets_1004)
            }
        }
    
    def _create_failure_result(self, section_idx: int, reason: str, 
                               section_bbox: List[float], w: int, h: int,
                               expanded_bbox: List[int] = None) -> Dict:
        """실패 결과 생성 헬퍼 메서드"""
        debug_info = {
            'original_bbox': section_bbox,
            'bbox_width': section_bbox[2] - section_bbox[0],
            'bbox_height': section_bbox[3] - section_bbox[1],
            'image_size': (w, h)
        }
        if expanded_bbox:
            debug_info['expanded_bbox'] = expanded_bbox
        
        return {
            'section_idx': section_idx,
            'problem_number_ocr': None,
            'answer_number': None,
            'correction': None,
            'section_crop_path': None,
            'problem_crop_path': None,
            'answer_1_crop_path': None,
            'answer_2_crop_path': None,
            'crop_success': False,
            'crop_failure_reason': reason,
            'used_resnet': False,
            'resnet_confidence': 0.0,
            'resnet_failed': False,
            'answer_source': None,
            'debug_info': debug_info
        }

    def filter_duplicate_sections(self, image_path: str, section_detections: List[Dict], 
                                 detections_1004: List[Dict]) -> List[Dict]:
        """중복된 section을 필터링"""
        if len(section_detections) <= 1:
            return section_detections
        
        image = cv2.imread(image_path)
        if image is None:
            logger.error(f"이미지 로드 실패: {image_path}")
            return section_detections
        
        h, w = image.shape[:2]
        
        section_with_problem = []
        
        for idx, section in enumerate(section_detections):
            sx1, sy1, sx2, sy2 = section['bbox']
            section_area = (sx2 - sx1) * (sy2 - sy1)
            
            problem_numbers = []
            for det in detections_1004:
                if det['class_name'] != 'problem_number':
                    continue
                
                dx1, dy1, dx2, dy2 = det['bbox']
                cx, cy = (dx1 + dx2) / 2, (dy1 + dy2) / 2
                
                if sx1 <= cx <= sx2 and sy1 <= cy <= sy2:
                    problem_numbers.append(det)
            
            if problem_numbers:
                best_problem = max(problem_numbers, key=lambda x: x['confidence'])
                
                x1, y1, x2, y2 = map(int, best_problem['bbox'])
                x1, y1 = max(0, x1), max(0, y1)
                x2, y2 = min(w, x2), min(h, y2)
                
                if x2 > x1 and y2 > y1:
                    cropped = image[y1:y2, x1:x2]
                    import tempfile
                    with tempfile.NamedTemporaryFile(suffix='.jpg', delete=True) as tmp:
                        cv2.imwrite(tmp.name, cropped)
                        problem_ocr = self.ocr.extract_number(tmp.name)
                        # 앞의 0 제거
                        problem_ocr = self._normalize_number(problem_ocr)
                else:
                    problem_ocr = None
            else:
                problem_ocr = None
            
            section_with_problem.append({
                'section': section,
                'original_index': idx,
                'problem_number_ocr': problem_ocr,
                'section_area': section_area,
                'bbox': section['bbox']
            })
        
        problem_groups = {}
        no_problem_sections = []
        
        for item in section_with_problem:
            problem_num = item['problem_number_ocr']
            
            if problem_num is None or problem_num == '':
                no_problem_sections.append(item)
            else:
                if problem_num not in problem_groups:
                    problem_groups[problem_num] = []
                problem_groups[problem_num].append(item)
        
        filtered_sections = []
        removed_count = 0
        
        for problem_num, items in problem_groups.items():
            if len(items) > 1:
                largest = max(items, key=lambda x: x['section_area'])
                filtered_sections.append(largest['section'])
                removed_count += len(items) - 1
            else:
                filtered_sections.append(items[0]['section'])
        
        for item in no_problem_sections:
            filtered_sections.append(item['section'])
        
        if removed_count > 0:
            logger.info(f"✂️ 중복 필터링: {removed_count}개 section 제거됨")
        
        filtered_sections = sorted(filtered_sections, key=lambda x: x['bbox'][1])
        
        return filtered_sections
    
    def process_page(self, image_path: str, output_dir: Path) -> Optional[Dict]:
        """페이지 처리 메인 함수
        
        Args:
            image_path: 이미지 경로
            output_dir: 출력 디렉토리 (S3 uploadUrl에 해당)
        
        Returns:
            Optional[Dict]: 처리 결과
            
        출력 구조:
            {output_dir}/
            └── {page_number}/
                └── {problem_number}/
                    └── {page_number}_{problem_number}_section.jpg
        """
        start_time = time.time()
        
        # 1004 모델: 페이지번호, 문제번호, section 검출
        logger.info("1004 모델 실행 중...")
        result_1004 = self.router_1004.route_infer_single_image(image_path)
        detections_1004 = result_1004['detections']
        
        section_detections = [d for d in detections_1004 if d['class_name'] == 'section']
        logger.info(f"1004 모델 Section 검출 개수: {len(section_detections)}")
        
        if not section_detections:
            logger.error(f"❌ Section이 하나도 검출되지 않았습니다!")
            return None
        
        page_name = Path(image_path).stem
        
        # 페이지 번호 OCR
        _, page_num_ocr = self.crop_page_number(image_path, detections_1004, output_dir)

        # 답지 필터링
        if not self.is_valid_page(page_num_ocr):
            logger.info(f"페이지 '{page_name}' (페이지 번호: {page_num_ocr})는 처리하지 않습니다.")
            return None
        
        # 1104 모델: answer_1, answer_2 검출
        logger.info("1104 모델 실행 중...")
        result_1104 = self.router_1104.route_infer_single_image(image_path)
        detections_1104 = result_1104['detections']

        # 중복 section 필터링
        section_detections = self.filter_duplicate_sections(image_path, section_detections, detections_1004)
        section_detections = sorted(section_detections, key=lambda x: x['bbox'][1])
        
        logger.info(f"페이지 '{page_name}': {len(section_detections)}개 Section 처리")

        recognized_problem_numbers = set()
        page_result = []
        crop_failure_count = 0
        
        for idx, det in enumerate(section_detections):
            section_bbox = det['bbox']
            section_result = self.process_single_section(
                image_path, idx, page_name, output_dir, section_bbox,
                detections_1004, detections_1104, page_num_ocr, recognized_problem_numbers
            )
            page_result.append(section_result)
            
            if section_result.get('problem_number_ocr'):
                recognized_problem_numbers.add(section_result['problem_number_ocr'])
            
            if not section_result.get('crop_success', True):
                crop_failure_count += 1

        end_time = time.time()
        
        if crop_failure_count > 0:
            logger.warning(f"⚠️ 페이지 '{page_name}': {crop_failure_count}개 Section crop 실패")
        
        return {
            "image_path": image_path,
            "page_name": page_name,
            "page_number_ocr": page_num_ocr,
            "sections": page_result,
            "processing_time": end_time - start_time,
            "total_sections": len(section_detections),
            "crop_failure_count": crop_failure_count
        }