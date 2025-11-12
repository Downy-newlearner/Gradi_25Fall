# yolo_test_crop.py
import logging
import time
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import cv2
import numpy as np
from models.Detection.Model_routing_1111.infer_and_evaluate import RoutedInference
from models.Recognition.ocr import OCRModel

# 로거 설정 수정: 파일에도 출력되도록
logger = logging.getLogger(__name__)
# basicConfig는 yolo_test.py에서 이미 설정되므로 여기서는 제거


class HierarchicalCropPipeline:
    """계층적 크롭 파이프라인: 페이지 → Section → 문제번호 및 정답 (OCR 포함)"""
    
    def __init__(self, model_dir: str, 
                 section_padding: int = 50,
                 answer_key_path: Optional[str] = None):
        """
        Args:
            model_dir: 모델 디렉토리 경로 (best_big_objects.pt, best_small_objects.pt 포함)
            section_padding: Section crop 시 추가할 여백 (픽셀). 기본값 50
            answer_key_path: 답지 파일 경로 (txt 파일)
        """
        self.router = RoutedInference(model_dir)
        self.ocr = OCRModel()
        self.section_padding = section_padding
        
        # 답지 로드
        self.answer_key = self._load_answer_key(answer_key_path) if answer_key_path else None
        
        logger.info("HierarchicalCropPipeline 초기화 (통합 모델 + OCR 모델 로드 완료)")
        logger.info("  - 1111 모델: 크롭 및 답안 추론용 (통합)")
        logger.info(f"  - Section padding: {section_padding}px")
        if self.answer_key:
            logger.info(f"  - 답지 로드 완료: {len(self.answer_key)}개 페이지")
    
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
                        page_num = parts[0]
                        problem_num = parts[1]
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
        """페이지 번호가 답지에 있는지 확인
        
        Args:
            page_number: OCR로 인식된 페이지 번호
            
        Returns:
            bool: 답지에 있으면 True, 답지가 없거나 페이지가 없으면 True (기본 처리)
        """
        if self.answer_key is None:
            # 답지가 없으면 모든 페이지 처리
            logger.info(f"답지가 없으므로 페이지 '{page_number}' 처리를 계속합니다.")
            return True
        
        if page_number is None:
            logger.warning("페이지 번호를 인식하지 못했습니다. 건너뜁니다.")
            return False
        
        # 페이지 번호 정규화 (공백 제거, 문자열 변환)
        page_number_normalized = str(page_number).strip()
        
        is_valid = page_number_normalized in self.answer_key
        
        if not is_valid:
            logger.warning(f"인식된 페이지 번호: '{page_number}' - 답지에 없습니다. 건너뜁니다.")
            logger.info(f"답지에 있는 페이지: {sorted(self.answer_key.keys())}")
        else:
            logger.info(f"인식된 페이지 번호: '{page_number}' - 답지에 있습니다. 처리를 계속합니다.")
        
        return is_valid
    
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
    
    def expand_bbox_with_padding(self, bbox: List[float], padding: int, img_width: int, img_height: int) -> List[int]:
        """바운딩 박스에 padding을 추가하되, 이미지 경계를 넘지 않도록 처리
        
        Args:
            bbox: [x1, y1, x2, y2]
            padding: 추가할 여백 (픽셀)
            img_width: 이미지 너비
            img_height: 이미지 높이
            
        Returns:
            List[int]: 확장된 바운딩 박스 [x1, y1, x2, y2]
        """
        x1, y1, x2, y2 = bbox
        
        # Padding 추가
        x1_expanded = max(0, int(x1 - padding))
        y1_expanded = max(0, int(y1 - padding))
        x2_expanded = min(img_width, int(x2 + padding))
        y2_expanded = min(img_height, int(y2 + padding))
        
        return [x1_expanded, y1_expanded, x2_expanded, y2_expanded]
    
    def is_bbox_near_section_boundary(self, bbox: List[float], section_bbox: List[float], threshold: int = 30) -> bool:
        """문제번호 박스가 section 경계 근처에 있는지 확인
        
        Args:
            bbox: 문제번호 바운딩 박스 [x1, y1, x2, y2]
            section_bbox: Section 바운딩 박스 [x1, y1, x2, y2]
            threshold: 경계로 간주할 거리 (픽셀)
            
        Returns:
            bool: 경계 근처에 있으면 True
        """
        bx1, by1, bx2, by2 = bbox
        sx1, sy1, sx2, sy2 = section_bbox
        
        # 상하좌우 경계와의 거리 계산
        dist_top = abs(by1 - sy1)
        dist_bottom = abs(by2 - sy2)
        dist_left = abs(bx1 - sx1)
        dist_right = abs(bx2 - sx2)
        
        # 하나라도 threshold 이내이면 경계 근처로 판단
        return min(dist_top, dist_bottom, dist_left, dist_right) < threshold
    
    def crop_page_number(self, image_path: str, detections: List[Dict], output_dir: Path) -> Tuple[Optional[str], Optional[str]]:
        """페이지 번호를 크롭하고 OCR로 인식
        
        Returns:
            Tuple[Optional[str], Optional[str]]: (크롭 이미지 경로, 인식된 페이지 번호)
        """
        image = cv2.imread(image_path)
        if image is None:
            logger.error(f"이미지 로드 실패: {image_path}")
            return None, None
        
        # 디버깅: 전체 검출 결과 확인
        logger.info(f"=" * 60)
        logger.info(f"📊 페이지 번호 검출 디버깅 시작: {Path(image_path).name}")
        logger.info(f"=" * 60)
        logger.info(f"전체 검출 개수: {len(detections)}")
        
        # 모든 클래스별 검출 개수 출력
        class_counts = {}
        for det in detections:
            class_name = det['class_name']
            class_counts[class_name] = class_counts.get(class_name, 0) + 1
        
        logger.info(f"클래스별 검출 개수:")
        for class_name, count in sorted(class_counts.items()):
            logger.info(f"  - {class_name}: {count}개")
        
        # page_number 클래스 필터링
        page_num_detections = [d for d in detections if d['class_name'] == 'page_number']
        
        logger.info(f"\n🔍 page_number 검출 상세:")
        logger.info(f"  검출 개수: {len(page_num_detections)}")
        
        if not page_num_detections:
            logger.warning(f"❌ YOLO 문제: 페이지 번호(page_number) 클래스가 검출되지 않았습니다!")
            logger.warning(f"  → 원인: YOLO 모델이 페이지 번호를 인식하지 못함")
            logger.warning(f"  → 해결방법:")
            logger.warning(f"     1. 모델 재학습 필요")
            logger.warning(f"     2. confidence threshold 조정 (현재: {self.router.small_conf})")
            logger.warning(f"     3. 이미지 품질 확인")
            
            # 디버깅용: 전체 이미지 저장 (page_number가 검출되지 않은 경우)
            debug_dir = output_dir / "debug_no_page_number"
            debug_dir.mkdir(parents=True, exist_ok=True)
            debug_image_path = debug_dir / f"{Path(image_path).stem}_full.jpg"
            cv2.imwrite(str(debug_image_path), image)
            logger.info(f"  디버깅용 전체 이미지 저장: {debug_image_path}")
            
            logger.info(f"=" * 60)
            return None, None
        
        # page_number 검출 상세 정보 출력
        for i, det in enumerate(page_num_detections, 1):
            logger.info(f"  [{i}] confidence: {det['confidence']:.4f}, bbox: {det['bbox']}")
        
        # 신뢰도 가장 높은 것 선택
        best_det = max(page_num_detections, key=lambda x: x['confidence'])
        logger.info(f"\n✅ 최고 신뢰도 검출 선택:")
        logger.info(f"  confidence: {best_det['confidence']:.4f}")
        logger.info(f"  bbox: {best_det['bbox']}")
        
        x1, y1, x2, y2 = map(int, best_det['bbox'])
        
        h, w = image.shape[:2]
        x1, y1 = max(0, x1), max(0, y1)
        x2, y2 = min(w, x2), min(h, y2)
        
        if x2 <= x1 or y2 <= y1:
            logger.warning(f"❌ 잘못된 페이지 번호 박스: {best_det['bbox']}")
            logger.warning(f"  → 원인: bbox 좌표가 유효하지 않음")
            logger.info(f"=" * 60)
            return None, None
        
        # 크롭 영역 정보
        crop_width = x2 - x1
        crop_height = y2 - y1
        logger.info(f"  크롭 영역 크기: {crop_width}x{crop_height} pixels")
        
        # 크롭 및 저장
        cropped = image[y1:y2, x1:x2]
        page_num_dir = output_dir / "page_numbers"
        page_num_dir.mkdir(parents=True, exist_ok=True)
        
        image_name = Path(image_path).stem
        save_path = page_num_dir / f"{image_name}_page_number.jpg"
        cv2.imwrite(str(save_path), cropped)
        logger.info(f"  크롭 이미지 저장: {save_path}")
        
        # OCR 전에 크롭 이미지 품질 확인
        if crop_width < 20 or crop_height < 20:
            logger.warning(f"⚠️ 크롭 영역이 너무 작습니다 ({crop_width}x{crop_height})")
            logger.warning(f"  → OCR 인식률이 낮을 수 있습니다")
        
        # OCR로 페이지 번호 인식
        logger.info(f"\n🔤 OCR 처리 중...")
        try:
            recognized_number = self.ocr.extract_number(str(save_path))
            
            if recognized_number is None or recognized_number == "":
                logger.warning(f"❌ OCR 문제: 페이지 번호를 인식하지 못했습니다!")
                logger.warning(f"  → 원인: OCR 모델이 텍스트를 인식하지 못함")
                logger.warning(f"  → 해결방법:")
                logger.warning(f"     1. 크롭 이미지 확인: {save_path}")
                logger.warning(f"     2. OCR 전처리 개선 필요")
                logger.warning(f"     3. 페이지 번호 영역에 padding 추가")
                logger.warning(f"     4. 이미지 해상도/품질 확인")
                
                # 디버깅용: OCR 실패한 크롭 이미지를 별도 디렉토리에 복사
                debug_ocr_dir = output_dir / "debug_ocr_failed"
                debug_ocr_dir.mkdir(parents=True, exist_ok=True)
                debug_ocr_path = debug_ocr_dir / f"{image_name}_page_number.jpg"
                cv2.imwrite(str(debug_ocr_path), cropped)
                logger.info(f"  OCR 실패 이미지 복사: {debug_ocr_path}")
            else:
                logger.info(f"✅ OCR 성공: '{recognized_number}'")
                
        except Exception as e:
            logger.error(f"❌ OCR 실행 중 오류 발생: {e}")
            import traceback
            traceback.print_exc()
            recognized_number = None
        
        logger.info(f"=" * 60)
        logger.info(f"📊 페이지 번호 검출 디버깅 완료\n")
        
        return str(save_path), recognized_number
    
    def process_single_section(self, original_image_path: str, section_idx: int, 
                            page_name: str, output_dir: Path, 
                            section_bbox: List[float], detections: List[Dict]) -> Dict:
        """섹션 내의 문제번호와 정답을 추론
        - 문제번호 크롭: problem_number 클래스 사용
        - 답안 추론: answer_1과 숫자(1-5) 클래스의 IoU 기반 정답 번호 결정
        
        Returns:
            Dict: {'section_idx', 'problem_number_ocr', 'answer_number', 'section_crop_path', 'problem_crop_path'}
        """
        sx1, sy1, sx2, sy2 = section_bbox
        image = cv2.imread(original_image_path)
        h, w = image.shape[:2]
        
        # Section 이미지 크롭 시 padding 추가
        expanded_section_bbox = self.expand_bbox_with_padding(
            [sx1, sy1, sx2, sy2], 
            self.section_padding, 
            w, h
        )
        sx1_exp, sy1_exp, sx2_exp, sy2_exp = expanded_section_bbox
        
        section_cropped = image[sy1_exp:sy2_exp, sx1_exp:sx2_exp]
        section_dir = output_dir / page_name / "sections"
        section_dir.mkdir(parents=True, exist_ok=True)
        
        section_crop_path = section_dir / f"section_{section_idx:02d}.jpg"
        cv2.imwrite(str(section_crop_path), section_cropped)
        logger.info(f"Section {section_idx} 이미지 저장 (padding {self.section_padding}px 추가): {section_crop_path}")
        
        # 확장된 영역 내의 검출 필터링
        section_dets_problem = []
        section_dets_answer = []
        
        for det in detections:
            dx1, dy1, dx2, dy2 = det['bbox']
            cx, cy = (dx1 + dx2) / 2, (dy1 + dy2) / 2
            
            # 확장된 영역 내에서 검출 (padding 고려)
            if sx1_exp <= cx <= sx2_exp and sy1_exp <= cy <= sy2_exp:
                if det['class_name'] == 'problem_number':
                    section_dets_problem.append(det)
                    # 경계 근처 여부 체크
                    if self.is_bbox_near_section_boundary(det['bbox'], [sx1, sy1, sx2, sy2]):
                        logger.warning(f"Section {section_idx}: 문제번호가 경계 근처에 위치 (padding으로 보정)")
                elif det['class_name'] in ['answer_1', '1', '2', '3', '4', '5']:
                    section_dets_answer.append(det)
        
        # 디버깅: 문제번호 검출 결과
        logger.info(f"Section {section_idx}: 문제번호 검출 개수 = {len(section_dets_problem)}")
        if section_dets_problem:
            for i, det in enumerate(section_dets_problem):
                logger.info(f"  문제번호 {i+1}: confidence={det['confidence']:.3f}, bbox={det['bbox']}")
        
        # 디버깅: 답안 검출 결과
        answer_1_dets = [d for d in section_dets_answer if d['class_name'] == 'answer_1']
        class_dets = [d for d in section_dets_answer if d['class_name'] in ['1', '2', '3', '4', '5']]
        
        logger.info(f"Section {section_idx}: answer_1 검출 개수 = {len(answer_1_dets)}")
        if answer_1_dets:
            for i, det in enumerate(answer_1_dets):
                logger.info(f"  answer_1 {i+1}: confidence={det['confidence']:.3f}, bbox={det['bbox']}")
        
        logger.info(f"Section {section_idx}: 숫자(1-5) 검출 개수 = {len(class_dets)}")
        if class_dets:
            for i, det in enumerate(class_dets):
                logger.info(f"  숫자 {det['class_name']}: confidence={det['confidence']:.3f}, bbox={det['bbox']}")

        # 문제번호 OCR 및 이미지 저장
        problem_ocr = None
        problem_crop_path = None
        if section_dets_problem:
            best_det = max(section_dets_problem, key=lambda x: x['confidence'])
            x1, y1, x2, y2 = map(int, best_det['bbox'])
            x1, y1 = max(0, x1), max(0, y1)
            x2, y2 = min(w, x2), min(h, y2)
            
            if x2 > x1 and y2 > y1:
                cropped = image[y1:y2, x1:x2]
                
                # Problem number 이미지 저장
                problem_dir = output_dir / page_name / "problem_numbers"
                problem_dir.mkdir(parents=True, exist_ok=True)
                problem_crop_path = problem_dir / f"section_{section_idx:02d}_problem_number.jpg"
                cv2.imwrite(str(problem_crop_path), cropped)
                logger.info(f"Section {section_idx} 문제번호 이미지 저장: {problem_crop_path}")
                
                # OCR 수행
                problem_ocr = self.ocr.extract_number(str(problem_crop_path))
                logger.info(f"Section {section_idx} 문제번호 OCR 결과: '{problem_ocr}'")
        else:
            logger.warning(f"Section {section_idx}: 문제번호 미검출")

        # answer_1과 class 1~5의 IoU 계산
        best_answer = None
        best_iou = 0.0
        debug_iou_info = []

        if answer_1_dets and class_dets:
            a_bbox = answer_1_dets[0]['bbox']
            logger.info(f"Section {section_idx}: answer_1 bbox = {a_bbox}")
            
            for det in class_dets:
                iou = self.calculate_iou(a_bbox, det['bbox'])
                debug_iou_info.append({
                    'class': det['class_name'],
                    'bbox': det['bbox'],
                    'iou': iou
                })
                logger.info(f"  IoU with {det['class_name']}: {iou:.4f}")
                
                if iou > best_iou:
                    best_iou = iou
                    best_answer = det['class_name']
            
            if best_answer:
                logger.info(f"Section {section_idx}: 최종 선택된 답안 = {best_answer} (IoU: {best_iou:.4f})")
            else:
                logger.warning(f"Section {section_idx}: IoU가 0인 경우 - 답안을 선택하지 못했습니다.")
        else:
            if not answer_1_dets:
                logger.warning(f"Section {section_idx}: answer_1이 검출되지 않았습니다.")
            if not class_dets:
                logger.warning(f"Section {section_idx}: 숫자(1-5)가 검출되지 않았습니다.")

        return {
            'section_idx': section_idx,
            'problem_number_ocr': problem_ocr,
            'answer_number': best_answer,
            'section_crop_path': str(section_crop_path),
            'problem_crop_path': str(problem_crop_path) if problem_crop_path else None,
            'is_boundary_issue': len(section_dets_problem) > 0 and any(
                self.is_bbox_near_section_boundary(d['bbox'], [sx1, sy1, sx2, sy2]) 
                for d in section_dets_problem
            ),
            'debug_info': {
                'answer_1_count': len(answer_1_dets),
                'class_count': len(class_dets),
                'iou_details': debug_iou_info,
                'best_iou': best_iou
            }
        }

    def process_page(self, image_path: str, output_dir: Path) -> Optional[Dict]:
        """페이지 처리: 통합 모델로 크롭 및 답안 추론
        
        Returns:
            Optional[Dict]: 처리 결과 반환
        """
        start_time = time.time()
        
        logger.info(f"\n{'='*80}")
        logger.info(f"🖼️  이미지 처리 시작: {Path(image_path).name}")
        logger.info(f"{'='*80}")
        
        # 통합 모델: 모든 객체 검출
        logger.info("통합 모델 실행 중 (모든 객체 검출)...")
        result = self.router.route_infer_single_image(image_path)
        detections = result['detections']
        
        logger.info(f"✅ 모델 추론 완료: 총 {len(detections)}개 객체 검출")
        
        page_name = Path(image_path).stem
        page_output_dir = output_dir / page_name
        page_output_dir.mkdir(parents=True, exist_ok=True)

        # 페이지 번호 검출 시도 (실패해도 계속 진행)
        logger.info(f"\n{'='*60}")
        logger.info(f"📄 페이지 번호 검출 시도 (실패해도 계속 진행)")
        logger.info(f"{'='*60}")
        
        page_num_path, page_num_ocr = self.crop_page_number(image_path, detections, page_output_dir)
        
        if page_num_ocr:
            logger.info(f"✅ 페이지 번호 인식 성공: '{page_num_ocr}'")
        else:
            logger.warning(f"⚠️ 페이지 번호 인식 실패 - 하지만 계속 진행합니다")
            page_num_ocr = "UNKNOWN"  # 인식 실패 시 기본값
        
        # 답지 필터링 비활성화 - 모든 이미지 처리
        logger.info(f"💡 답지 필터링 비활성화 - 모든 이미지를 처리합니다")

        # Section 영역 검출
        section_detections = [d for d in detections if d['class_name'] == 'section']
        section_detections = sorted(section_detections, key=lambda x: x['bbox'][1])
        
        logger.info(f"\n📑 페이지 '{page_name}': {len(section_detections)}개 Section 검출")
        
        if len(section_detections) == 0:
            logger.warning(f"⚠️ Section이 검출되지 않았습니다. 이미지를 건너뜁니다.")
            return None

        page_result = []
        for idx, det in enumerate(section_detections):
            section_bbox = det['bbox']
            section_result = self.process_single_section(
                image_path, idx, page_name, output_dir, section_bbox, detections
            )
            page_result.append(section_result)

        end_time = time.time()
        
        logger.info(f"\n✅ 페이지 '{page_name}' 처리 완료 ({end_time - start_time:.2f}초)")
        logger.info(f"{'='*80}\n")
        
        return {
            "image_path": image_path,
            "page_name": page_name,
            "page_number_ocr": page_num_ocr,
            "sections": page_result,
            "processing_time": end_time - start_time
        }