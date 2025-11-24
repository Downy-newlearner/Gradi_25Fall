# Model_routing_1004/run_routed_inference.py
"""
라우팅 추론 스크립트 (Post-processing 통합)
YOLOv8n (큰 객체)과 YOLOv8s (작은 객체) 모델을 결합하여 추론을 수행합니다.
section 검출 후 post-processing을 적용하여 영역을 정교하게 조정합니다.
"""

import os
import sys
import json
import cv2
import numpy as np
from pathlib import Path
from typing import List, Dict, Tuple
from ultralytics import YOLO
from datetime import datetime
import copy

# 클래스 라우팅 정의 (1, 2, 3, 4, 5 추가)
SMALL_CLASSES = {"page_number", "problem_number", "answer_1", "answer_2", "1", "2", "3", "4", "5"}
LARGE_CLASSES = {"korean_content", "english_content", "section", "answer_option"}

# 클래스별 색상 정의
CLASS_COLORS = {
    # 큰 객체 클래스
    'answer_option': (0, 255, 0),      # 녹색
    'english_content': (255, 0, 0),    # 빨간색
    'korean_content': (0, 0, 255),     # 파란색
    'section': (255, 255, 0),          # 노란색
    'original_section': (0, 165, 255), # 주황색 (원본 section)
    
    # 작은 객체 클래스
    'page_number': (255, 0, 255),      # 마젠타
    'problem_number': (0, 255, 255),   # 시안
    'answer_1': (255, 165, 0),         # 오렌지
    'answer_2': (128, 0, 128),         # 보라
    
    # 숫자 클래스
    '1': (255, 192, 203),              # 핑크
    '2': (144, 238, 144),              # 라이트그린
    '3': (173, 216, 230),              # 라이트블루
    '4': (255, 218, 185),              # 피치
    '5': (221, 160, 221)               # 플럼
}


def is_blank_region(image, roi, mean_thresh=240, stddev_thresh=15, edge_ratio_thresh=0.005):
    """
    이미지에서 roi 영역이 '공백'인지 판단하는 함수.
    - image: numpy array (H, W, 3)
    - roi: (x_min, y_min, x_max, y_max)
    - mean_thresh: 평균 픽셀 임계값 (default 240)
    - stddev_thresh: 표준편차 임계값 (default 15)
    - edge_ratio_thresh: 엣지 비율 임계값 (default 0.005 == 0.5%)
    """
    x_min, y_min, x_max, y_max = roi

    # ROI를 이미지 크기 내로 clip
    h, w = image.shape[:2]
    x_min = max(0, int(round(x_min)))
    y_min = max(0, int(round(y_min)))
    x_max = min(w, int(round(x_max)))
    y_max = min(h, int(round(y_max)))

    if x_max <= x_min or y_max <= y_min:
        return True  # 잘못된 ROI는 공백으로 간주

    roi_img = image[y_min:y_max, x_min:x_max]

    # Gray 변환
    if len(roi_img.shape) == 3:
        roi_gray = cv2.cvtColor(roi_img, cv2.COLOR_BGR2GRAY)
    else:
        roi_gray = roi_img

    mean = np.mean(roi_gray)
    stddev = np.std(roi_gray)

    # Canny Edge
    v = np.median(roi_gray)
    lower = int(max(0, 0.66 * v))
    upper = int(min(255, 1.33 * v))
    edges = cv2.Canny(roi_gray, lower, upper)
    edge_ratio = np.sum(edges > 0) / (roi_gray.shape[0]*roi_gray.shape[1]+1e-5)

    # 공백 판정
    result = (mean >= mean_thresh and stddev <= stddev_thresh and edge_ratio <= edge_ratio_thresh)
    return result


class RoutedInference:
    def __init__(self, base_dir: str):
        self.base_dir = Path(base_dir)
        self.small_model_dir = self.base_dir / "yolov8s_imgsz_2048"
        self.large_model_dir = self.base_dir / "yolov8n_imgsz_1280"
        
        # 모델 경로
        self.small_model_path = self.small_model_dir / "train" / "weights" / "best.pt"
        self.large_model_path = self.large_model_dir / "train" / "weights" / "best.pt"
        
        # 모델 로드
        self.small_model = self._load_model(self.small_model_path, "yolov8s.pt")
        self.large_model = self._load_model(self.large_model_path, "yolov8n.pt")
        
        # 추론 파라미터
        self.small_conf = 0.22
        self.large_conf = 0.12
        
        # Post-processing 파라미터
        self.roi_height = 60  # 첫 번째 확장은 60px, 이후는 5px씩
        
        print(f"✅ Small model loaded: {self.small_model_path}")
        print(f"✅ Large model loaded: {self.large_model_path}")
    
    def _load_model(self, model_path: Path, fallback: str):
        """모델 로드"""
        if model_path.exists():
            return YOLO(str(model_path))
        else:
            print(f"⚠️ Model not found: {model_path}, using {fallback}")
            return YOLO(fallback)
    
    def get_all_detections(self, results, class_names: List[str]) -> List[Dict]:
        """
        모든 검출 결과를 반환
        """
        all_detections = []
        
        if results.boxes is not None:
            for box in results.boxes:
                cls_id = int(box.cls[0])
                confidence = float(box.conf[0])
                xyxy = box.xyxy[0].tolist()
                
                if cls_id < len(class_names):
                    class_name = class_names[cls_id]
                    
                    all_detections.append({
                        'class_name': class_name,
                        'class_id': cls_id,
                        'confidence': confidence,
                        'bbox': xyxy
                    })
        
        return all_detections
    
    def apply_section_postprocessing(self, image: np.ndarray, detections: List[Dict]) -> List[Dict]:
        """
        Section에 대해 post-processing 적용
        - section이 없으면 problem_number 기반으로 생성
        - section 확장 시 다른 problem_number를 침범하지 않도록 제한
        """
        # problem_number의 왼쪽 위 좌표 수집 및 Y 좌표 기준 정렬
        question_numbers = []
        for det in detections:
            if det['class_name'] == 'problem_number':
                question_numbers.append({
                    'bbox': det['bbox'],
                    'confidence': det['confidence']
                })
        
        # Y 좌표 기준으로 정렬 (위에서 아래로)
        question_numbers.sort(key=lambda x: x['bbox'][1])
        
        # section 검출 결과
        section_detections = [det for det in detections if det['class_name'] == 'section']
        
        print(f"  📌 발견된 problem_number: {len(question_numbers)}개")
        print(f"  📦 발견된 section: {len(section_detections)}개")
        
        # section이 없지만 problem_number가 있는 경우 → section 생성
        if len(section_detections) == 0 and len(question_numbers) > 0:
            print(f"  ⚠️ Section이 없지만 problem_number가 있음 → Section 자동 생성")
            
            for idx, qn in enumerate(question_numbers):
                qn_bbox = qn['bbox']
                qn_x1, qn_y1, qn_x2, qn_y2 = qn_bbox
                
                # 1. problem_number의 왼쪽 상단 꼭짓점 기준으로 초기 확장 (좌측 10px, 상단 10px)
                section_x1 = max(0, qn_x1 - 10)
                section_y1 = max(0, qn_y1 - 10)

                # 2. 오른쪽으로 600px, 아래쪽으로 900px 확장
                h, w = image.shape[:2]
                section_x2 = min(w, section_x1 + 600)
                section_y2 = min(h, section_y1 + 900)
                
                # 다음 problem_number의 상단 Y 좌표 찾기
                next_pn_y = h  # 기본값: 이미지 하단
                if idx + 1 < len(question_numbers):
                    next_pn_y = question_numbers[idx + 1]['bbox'][1]
                    print(f"       📍 다음 problem_number 위치: y={next_pn_y:.1f}")
                
                # 3. ROI 기반 오른쪽 확장 (5px씩)
                right_expansion_count = 0
                max_expansions = 1000  # 최대 확장 횟수
                
                while right_expansion_count < max_expansions:
                    if section_x2 + 5 > w:
                        break
                    
                    right_roi = [section_x2, section_y1, section_x2 + 5, section_y2]
                    
                    if not is_blank_region(image, right_roi):
                        section_x2 += 5
                        right_expansion_count += 1
                    else:
                        break
                
                # 4. ROI 기반 아래쪽 확장 (5px씩) - 다음 problem_number 고려
                bottom_expansion_count = 0
                
                while bottom_expansion_count < max_expansions:
                    if section_y2 + 5 > h:
                        break
                    
                    # 다음 problem_number의 상단을 침범하지 않도록 확인
                    if section_y2 + 5 > next_pn_y:
                        print(f"       ⛔ 다음 problem_number 영역 도달 (y={next_pn_y:.1f})")
                        break
                    
                    bottom_roi = [section_x1, section_y2, section_x2, section_y2 + 5]
                    
                    if not is_blank_region(image, bottom_roi):
                        section_y2 += 5
                        bottom_expansion_count += 1
                    else:
                        break
                
                # 생성된 section을 detections에 추가
                generated_section = {
                    'class_name': 'section',
                    'class_id': 3,  # section의 class_id
                    'confidence': qn['confidence'],  # problem_number의 confidence 사용
                    'bbox': [section_x1, section_y1, section_x2, section_y2],
                    'generated': True  # 생성된 section임을 표시
                }
                
                section_detections.append(generated_section)
                print(f"       ✅ Section 생성 완료: [{section_x1:.1f}, {section_y1:.1f}, {section_x2:.1f}, {section_y2:.1f}]")
        
        # 결과 저장용 리스트
        processed_detections = []
        
        # section 이외의 객체들은 그대로 유지
        for det in detections:
            if det['class_name'] != 'section':
                processed_detections.append(det)
        
        # section에 대해 post-processing 적용
        for det in section_detections:
            if det.get('generated', False):
                # 생성된 section은 이미 확장이 완료됨
                processed_detections.append(det)
                print(f"  ✨ 생성된 Section 추가 완료")
                continue
            
            # 원본 section 저장
            original_section = copy.deepcopy(det)
            original_section['class_name'] = 'original_section'
            processed_detections.append(original_section)
            
            # 처리할 section 복사
            section = copy.deepcopy(det)
            x_min, y_min, x_max, y_max = section['bbox']
            
            print(f"  🔧 Section 처리 시작: bbox=({x_min:.1f}, {y_min:.1f}, {x_max:.1f}, {y_max:.1f})")
            
            # 현재 section과 연관된 problem_number 찾기
            current_pn_idx = -1
            next_pn_y = image.shape[0]  # 기본값: 이미지 하단
            
            for idx, qn in enumerate(question_numbers):
                qn_y = qn['bbox'][1]
                # section 영역 내에 있는 problem_number 찾기
                if y_min <= qn_y <= y_max:
                    current_pn_idx = idx
                    break
            
            # 다음 problem_number의 Y 좌표 찾기
            if current_pn_idx != -1 and current_pn_idx + 1 < len(question_numbers):
                next_pn_y = question_numbers[current_pn_idx + 1]['bbox'][1]
                print(f"    📍 다음 problem_number 위치: y={next_pn_y:.1f}")
            
            # 1. 가장 가까운 problem_number에 왼쪽 위 맞추기
            if question_numbers:
                min_dist = float('inf')
                nearest_qn = None
                for qn in question_numbers:
                    qn_x, qn_y = qn['bbox'][0], qn['bbox'][1]
                    dist = np.sqrt((qn_x - x_min)**2 + (qn_y - y_min)**2)
                    if dist < min_dist:
                        min_dist = dist
                        nearest_qn = (qn_x, qn_y)
                
                if nearest_qn is not None:
                    x_min = max(0, nearest_qn[0] - 20)  # 조정값
                    y_min = nearest_qn[1]
                    print(f"    ↔️ problem_number 정렬: ({nearest_qn[0]:.1f}, {nearest_qn[1]:.1f})")
            
            # 2. 위쪽 확장 (첫 번째: 60px, 이후: 5px씩)
            print(f"    ⬆️ 위쪽 확장 시작 (첫 번째: {self.roi_height}px, 이후: 5px씩)")
            expansion_count = 0
            stopped_by_boundary_top = False  # 경계로 인해 중단되었는지 추적
            
            while True:
                # 첫 번째 확장은 roi_height, 이후는 5px씩
                if expansion_count == 0:
                    expansion_size = self.roi_height
                else:
                    expansion_size = 5
                
                if y_min - expansion_size < 0:
                    print(f"      ⛔ 이미지 상단 경계 도달 ({expansion_count}번 확장 후)")
                    stopped_by_boundary_top = True
                    break
                
                top_upside_roi = [x_min, y_min - expansion_size, x_max, y_min]
                
                if not is_blank_region(image, top_upside_roi):
                    y_min -= expansion_size
                    expansion_count += 1
                    if expansion_count == 1:
                        print(f"      ⬆️ 위로 확장 (1차: {self.roi_height}px): y_min={y_min:.1f}")
                    else:
                        print(f"      ⬆️ 위로 확장 ({expansion_count}차: 5px): y_min={y_min:.1f}")
                else:
                    print(f"      ⏹️ 공백 영역 도달 ({expansion_count}번 확장 후)")
                    break
            
            # 위쪽이 경계로 중단되지 않았고, 첫 확장이 안 된 경우 padding 미적용
            if expansion_count == 0:
                print(f"      ⚠️ 위쪽 확장 없음 → padding 미적용")
            
            # 3. 아래쪽 확장 (첫 번째: 60px, 이후: 5px씩) - 다음 problem_number 고려
            print(f"    ⬇️ 아래쪽 확장 시작 (첫 번째: {self.roi_height}px, 이후: 5px씩)")
            expansion_count = 0
            stopped_by_pn_bottom = False  # problem_number로 인해 중단되었는지 추적
            
            while True:
                # 첫 번째 확장은 roi_height, 이후는 5px씩
                if expansion_count == 0:
                    expansion_size = self.roi_height
                else:
                    expansion_size = 5
                
                if y_max + expansion_size > image.shape[0]:
                    print(f"      ⛔ 이미지 하단 경계 도달 ({expansion_count}번 확장 후)")
                    break
                
                # 다음 problem_number의 상단을 침범하지 않도록 확인
                if y_max + expansion_size > next_pn_y:
                    print(f"      ⛔ 다음 problem_number 영역 도달 (y={next_pn_y:.1f}, {expansion_count}번 확장 후)")
                    stopped_by_pn_bottom = True
                    break
                
                bottom_downside_roi = [x_min, y_max, x_max, y_max + expansion_size]
                
                if not is_blank_region(image, bottom_downside_roi):
                    y_max += expansion_size
                    expansion_count += 1
                    if expansion_count == 1:
                        print(f"      ⬇️ 아래로 확장 (1차: {self.roi_height}px): y_max={y_max:.1f}")
                    else:
                        print(f"      ⬇️ 아래로 확장 ({expansion_count}차: 5px): y_max={y_max:.1f}")
                else:
                    print(f"      ⏹️ 공백 영역 도달 ({expansion_count}번 확장 후)")
                    break
            
            # 아래쪽이 problem_number로 중단된 경우 padding 미적용
            if stopped_by_pn_bottom:
                print(f"      ⚠️ 아래쪽이 problem_number로 중단됨 → padding 미적용")
            
            # 교정된 section 저장
            section['bbox'] = [x_min, y_min, x_max, y_max]
            processed_detections.append(section)
            
            print(f"  ✅ Section 처리 완료: bbox=({x_min:.1f}, {y_min:.1f}, {x_max:.1f}, {y_max:.1f})")
        
        return processed_detections
    
    def route_infer_single_image(self, image_path: str) -> Dict:
        """
        단일 이미지에 대해 라우팅 추론 수행 (post-processing 포함)
        """
        # 이미지 로드
        image = cv2.imread(str(image_path))
        if image is None:
            raise ValueError(f"이미지를 로드할 수 없습니다: {image_path}")
        
        # 작은 객체 모델 추론 (YOLOv8s @ 2048)
        small_results = self.small_model(str(image_path), imgsz=2048, conf=self.small_conf, verbose=False)[0]
        small_class_names = ['page_number', 'problem_number', 'answer_1', 'answer_2', '1', '2', '3', '4', '5']
        small_detections = self.get_all_detections(small_results, small_class_names)
        
        # 큰 객체 모델 추론 (YOLOv8n @ 1280)
        large_results = self.large_model(str(image_path), imgsz=1280, conf=self.large_conf, verbose=False)[0]
        large_class_names = ['answer_option', 'english_content', 'korean_content', 'section']
        large_detections = self.get_all_detections(large_results, large_class_names)
        
        # 결과 병합
        all_detections = small_detections + large_detections
        
        # Section에 대해 post-processing 적용
        print(f"  🔄 Section post-processing 적용")
        processed_detections = self.apply_section_postprocessing(image, all_detections)
        
        return {
            'image_path': str(image_path),
            'detections': processed_detections,
            'small_detections': small_detections,
            'large_detections': large_detections,
            'timestamp': datetime.now().isoformat()
        }
    
    def visualize_detections(self, image_path: str, detections: List[Dict], output_path: str):
        """
        검출 결과를 시각화하여 저장
        """
        # 이미지 로드
        image = cv2.imread(str(image_path))
        if image is None:
            print(f"❌ 이미지 로드 실패: {image_path}")
            return
        
        # 각 검출 결과 그리기
        for det in detections:
            class_name = det['class_name']
            confidence = det['confidence']
            bbox = det['bbox']
            color = CLASS_COLORS.get(class_name, (255, 255, 255))
            
            # 바운딩 박스 좌표
            x1, y1, x2, y2 = map(int, bbox)
            
            # 바운딩 박스 그리기 (original_section은 점선으로)
            if class_name == 'original_section':
                # 점선 효과 (선분을 여러 개 그려서 점선처럼 보이게)
                dash_length = 10
                for i in range(x1, x2, dash_length * 2):
                    cv2.line(image, (i, y1), (min(i + dash_length, x2), y1), color, 2)
                    cv2.line(image, (i, y2), (min(i + dash_length, x2), y2), color, 2)
                for i in range(y1, y2, dash_length * 2):
                    cv2.line(image, (x1, i), (x1, min(i + dash_length, y2)), color, 2)
                    cv2.line(image, (x2, i), (x2, min(i + dash_length, y2)), color, 2)
            else:
                cv2.rectangle(image, (x1, y1), (x2, y2), color, 3)
            
            # 라벨 텍스트
            label = f"{class_name}: {confidence:.3f}"
            
            # 텍스트 배경 그리기
            (text_width, text_height), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.7, 2)
            cv2.rectangle(image, (x1, y1 - text_height - 10), (x1 + text_width, y1), color, -1)
            
            # 텍스트 그리기
            cv2.putText(image, label, (x1, y1 - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
        
        # 범례 추가
        self.add_legend(image)
        
        # 이미지 저장
        cv2.imwrite(str(output_path), image)
        
    def crop_and_save_detections(self, image_path: str, detections: List[Dict], output_dir: Path):
        """각 검출 결과 개별 이미지로 크롭하여 저장"""
        # 이미지 로드
        image = cv2.imread(str(image_path))
        if image is None:
            print(f"❌ 이미지 로드 실패: {image_path}")
            return
    
        image_name = Path(image_path).stem
    
        # 클래스별 카운터
        class_counters = {}
    
        for det in detections:
            class_name = det['class_name']
            confidence = det['confidence']
            bbox = det['bbox']
        
            # 바운딩 박스 좌표
            x1, y1, x2, y2 = map(int, bbox)
        
            # 좌표 보정
            h, w = image.shape[:2]
            x1, y1 = max(0, x1), max(0, y1)
            x2, y2 = min(w, x2), min(h, y2)
        
            if x2 <= x1 or y2 <= y1:
                continue
        
            # 크롭
            cropped = image[y1:y2, x1:x2]
        
            # 클래스별 폴더 생성
            class_dir = output_dir / image_name / class_name
            class_dir.mkdir(parents=True, exist_ok=True)
        
            # 카운터 증가
            if class_name not in class_counters:
                class_counters[class_name] = 0
            else:
                class_counters[class_name] += 1
        
            # 파일명 생성 및 저장
            crop_filename = f"{class_name}_{class_counters[class_name]:02d}_conf{confidence:.3f}.jpg"
            cv2.imwrite(str(class_dir / crop_filename), cropped)
            
    def crop_by_class_only(self, image_path: str, detections: List[Dict], output_dir: Path, class_counters: Dict[str, int]):
        # 이미지 로드
        image = cv2.imread(str(image_path))
        if image is None:
            print(f"❌ 이미지 로드 실패: {image_path}")
            return class_counters
    
        image_name = Path(image_path).stem
    
        for det in detections:
            class_name = det['class_name']
            confidence = det['confidence']
            bbox = det['bbox']
        
            # 바운딩 박스 좌표
            x1, y1, x2, y2 = map(int, bbox)
        
            # 좌표 보정
            h, w = image.shape[:2]
            x1, y1 = max(0, x1), max(0, y1)
            x2, y2 = min(w, x2), min(h, y2)
        
            if x2 <= x1 or y2 <= y1:
                continue
        
            # 크롭
            cropped = image[y1:y2, x1:x2]
        
            # 클래스별 폴더 생성 (페이지 구분 없음)
            class_dir = output_dir / class_name
            class_dir.mkdir(parents=True, exist_ok=True)
        
            # 전역 카운터 증가
            if class_name not in class_counters:
                class_counters[class_name] = 0
        
            # 파일명: 페이지명_카운터_신뢰도
            crop_filename = f"{image_name}_{class_name}_{class_counters[class_name]:03d}_conf{confidence:.3f}.jpg"
            cv2.imwrite(str(class_dir / crop_filename), cropped)
        
            class_counters[class_name] += 1
    
        return class_counters
    
    def add_legend(self, image):
        """범례 추가"""
        legend_y = 30
        all_classes = list(CLASS_COLORS.keys())
        
        for i, class_name in enumerate(all_classes):
            color = CLASS_COLORS[class_name]
            # 색상 박스
            cv2.rectangle(image, (10, legend_y + i * 30), (30, legend_y + i * 30 + 25), color, -1)
            # 클래스 이름
            cv2.putText(image, class_name, (35, legend_y + i * 30 + 18), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
    
    def process_test_images(self, test_data_root: str, output_dir: str):
        """
        테스트 이미지들에 대해 라우팅 추론 수행
        """
        test_data_path = Path(test_data_root)
        output_path = Path(output_dir)
        
        # 출력 디렉토리 생성
        (output_path / "images").mkdir(parents=True, exist_ok=True)
        (output_path / "annotations").mkdir(parents=True, exist_ok=True)
        
        # 테스트 이미지 목록 가져오기
        test_images_dir = test_data_path 
        if not test_images_dir.exists():
            print(f"❌ 테스트 이미지 디렉토리를 찾을 수 없습니다: {test_images_dir}")
            return
        
        image_extensions = ['.jpg', '.jpeg', '.png', '.bmp']
        image_files = []
        for ext in image_extensions:
            image_files.extend(test_images_dir.glob(f"*{ext}"))
            image_files.extend(test_images_dir.glob(f"*{ext.upper()}"))
        
        image_files = sorted(image_files)
        print(f"📊 테스트 이미지 {len(image_files)}개 발견")
        
        # 결과 저장용
        all_results = []
        total_detections = 0
        class_counts = {name: 0 for name in CLASS_COLORS.keys()}
        total_confidence = 0
        
        global_class_counters = {} # 전역 카운터
        
        print(f"🔍 {len(image_files)}개 이미지에 대해 라우팅 추론 시작...")
        
        for i, image_path in enumerate(image_files):
            print(f"\n처리 중: {i+1}/{len(image_files)} - {image_path.name}")
            
            # 라우팅 추론 수행 (post-processing 포함)
            result = self.route_infer_single_image(str(image_path))
            all_results.append(result)
            
            # 시각화 이미지 저장
            output_image_path = output_path / "images" / f"routed_result_{image_path.stem}.jpg"
            self.visualize_detections(str(image_path), result['detections'], str(output_image_path))
            
            # 크롭된 이미지 저장 
            detailed_output_dir = output_path / "detailed_images"
            self.crop_and_save_detections(str(image_path), result['detections'], detailed_output_dir)
            
            # 클래스별 크롭 저장 (페이지 구분 없음)
            class_output_dir = output_path / "class_images"
            global_class_counters = self.crop_by_class_only(str(image_path), result['detections'], class_output_dir, global_class_counters)
            
            # JSON 저장
            output_json_path = output_path / "annotations" / f"routed_result_{image_path.stem}.json"
            with open(output_json_path, 'w', encoding='utf-8') as f:
                json.dump(result, f, indent=2, ensure_ascii=False)
            
            # 통계 업데이트
            for det in result['detections']:
                total_detections += 1
                class_name = det['class_name']
                if class_name in class_counts:
                    class_counts[class_name] += 1
                total_confidence += det['confidence']
        
        # 결과 요약 저장
        avg_confidence = total_confidence / total_detections if total_detections > 0 else 0
        summary = {
            "total_images": len(image_files),
            "processed_images": len(image_files),
            "total_detections": total_detections,
            "average_detections_per_image": total_detections / len(image_files) if image_files else 0,
            "class_counts": class_counts,
            "average_confidence": avg_confidence,
            "routing_strategy": {
                "small_objects": list(SMALL_CLASSES),
                "large_objects": list(LARGE_CLASSES),
                "small_model_conf": self.small_conf,
                "large_model_conf": self.large_conf
            },
            "postprocessing_applied": True,
            "roi_height": self.roi_height
        }
        
        summary_path = output_path / "routing_results_summary.json"
        with open(summary_path, 'w', encoding='utf-8') as f:
            json.dump(summary, f, indent=2, ensure_ascii=False)
        
        # 결과 출력
        print("\n" + "=" * 60)
        print("📊 라우팅 추론 결과 요약:")
        print(f"  - 처리된 이미지: {summary['processed_images']}/{summary['total_images']}")
        print(f"  - 총 검출 수: {summary['total_detections']}")
        print(f"  - 이미지당 평균 검출 수: {summary['average_detections_per_image']:.1f}")
        print(f"  - 평균 신뢰도: {summary['average_confidence']:.3f}")
        print(f"  - Post-processing 적용: ✅")
        print("\n📈 클래스별 검출 수:")
        for class_name, count in summary['class_counts'].items():
            print(f"  - {class_name}: {count}")
        
        print(f"\n✅ 결과 저장 완료: {output_path}")
        print(f"  - 시각화 이미지: {output_path}/images/")
        print(f"  - 검출 데이터: {output_path}/annotations/")
        print(f"  - 결과 요약: {output_path}/routing_results_summary.json")
        
        return all_results


def main():
    # 경로 설정
    current_dir = Path(__file__).parent
    test_data_root = current_dir.parent.parent / "recognition" / "exp_images"
    output_dir = current_dir / "routed_inference_results"
    
    print("🚀 라우팅 추론 시작 (Post-processing 포함)")
    print(f"📁 테스트 데이터: {test_data_root}")
    print(f"📁 출력 디렉토리: {output_dir}")
    print("=" * 60)
    
    try:
        # 라우팅 추론 실행
        router = RoutedInference(str(current_dir))
        results = router.process_test_images(str(test_data_root), str(output_dir))
        
        print("\n✅ 라우팅 추론 완료!")
        
    except Exception as e:
        print(f"❌ 오류 발생: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0


if __name__ == "__main__":
    exit(main())