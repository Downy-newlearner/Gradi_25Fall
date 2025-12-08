# infer_and_evaluate.py
"""
라우팅 추론 및 평가 스크립트
큰 객체 탐지 -> 작은 객체 탐지 -> 후처리 순서로 실행
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
import sys

# post-processing 모듈 import
post_processing_dir = Path(__file__).parent / "post_processing"
sys.path.insert(0, str(post_processing_dir))
import importlib.util
spec = importlib.util.spec_from_file_location("post_processing", post_processing_dir / "post-processing.py")
post_processing_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(post_processing_module)
post_processing = post_processing_module.post_processing
visualize_detections = post_processing_module.visualize_detections

# 클래스 라우팅 정의
SMALL_CLASSES = {"page_number", "problem_number", "answer_1", "answer_2"}
LARGE_CLASSES = {"korean_content", "english_content", "section", "answer_option"}

# 전체 클래스 목록 (data.yaml 기준)
ALL_CLASSES = ['1', '2', '3', '4', '5', 'answer_1', 'answer_2', 'answer_option', 
               'english_content', 'korean_content', 'page_number', 'problem_number', 'section']

# 클래스별 색상 정의 (참고용, 실제 시각화는 post-processing.py의 visualize_detections 사용)
CLASS_COLORS = {
    # 큰 객체 클래스
    'answer_option': (0, 255, 0),      # 녹색
    'english_content': (255, 0, 0),    # 빨간색
    'korean_content': (0, 0, 255),     # 파란색
    'section': (255, 255, 0),          # 노란색
    'original_section': (0, 0, 255),   # 빨간색 (원본 section)
    
    # 작은 객체 클래스
    'page_number': (255, 0, 255),      # 마젠타
    'problem_number': (0, 255, 255),   # 시안
    'answer_1': (255, 165, 0),         # 오렌지
    'answer_2': (128, 0, 128),         # 보라
    
    # 숫자 클래스
    '1': (255, 200, 0),
    '2': (200, 255, 0),
    '3': (0, 255, 200),
    '4': (0, 200, 255),
    '5': (200, 0, 255),
}

class RoutedInference:
    def __init__(self, model_dir: str):
        """
        라우팅 추론 클래스 초기화
        
        Args:
            model_dir: 모델 디렉토리 경로 (best_big_objects.pt, best_small_objects.pt 포함)
        """
        self.model_dir = Path(model_dir)
        
        # 모델 경로
        self.large_model_path = self.model_dir / "models" / "best_big_objects.pt"
        self.small_model_path = self.model_dir / "models" / "best_small_objects.pt"
        
        # 모델 로드
        print(f"📦 큰 객체 모델 로딩: {self.large_model_path}")
        self.large_model = self._load_model(self.large_model_path)
        
        print(f"📦 작은 객체 모델 로딩: {self.small_model_path}")
        self.small_model = self._load_model(self.small_model_path)
        
        # 클래스 이름 가져오기
        self.large_class_names = self._get_class_names(self.large_model)
        self.small_class_names = self._get_class_names(self.small_model)
        
        print(f"✅ 큰 객체 클래스: {self.large_class_names}")
        print(f"✅ 작은 객체 클래스: {self.small_class_names}")
        
        # 추론 파라미터
        self.large_conf = 0.5
        self.small_conf = 0.4
        self.iou_threshold = 0.5  # 겹침 제거를 위한 IOU 임계값
    
    def _load_model(self, model_path: Path):
        """모델 로드"""
        if not model_path.exists():
            raise FileNotFoundError(f"모델 파일을 찾을 수 없습니다: {model_path}")
        return YOLO(str(model_path))
    
    def _get_class_names(self, model):
        """모델에서 클래스 이름 가져오기"""
        if hasattr(model, 'names') and model.names:
            # model.names는 딕셔너리이므로 값들을 리스트로 변환
            names_dict = model.names
            # 클래스 ID 순서대로 정렬
            max_id = max(names_dict.keys()) if names_dict else -1
            class_names = [names_dict.get(i, f'class_{i}') for i in range(max_id + 1)]
            return class_names
        return ALL_CLASSES
    
    def _calculate_iou(self, bbox1: List[float], bbox2: List[float]) -> float:
        """
        두 bounding box 간의 IOU(Intersection over Union) 계산
        
        Args:
            bbox1: [x_min, y_min, x_max, y_max]
            bbox2: [x_min, y_min, x_max, y_max]
        
        Returns:
            IOU 값 (0.0 ~ 1.0)
        """
        x1_min, y1_min, x1_max, y1_max = bbox1
        x2_min, y2_min, x2_max, y2_max = bbox2
        
        # 교집합 영역 계산
        inter_x_min = max(x1_min, x2_min)
        inter_y_min = max(y1_min, y2_min)
        inter_x_max = min(x1_max, x2_max)
        inter_y_max = min(y1_max, y2_max)
        
        # 교집합이 없는 경우
        if inter_x_max <= inter_x_min or inter_y_max <= inter_y_min:
            return 0.0
        
        # 교집합 면적
        inter_area = (inter_x_max - inter_x_min) * (inter_y_max - inter_y_min)
        
        # 각 박스의 면적
        bbox1_area = (x1_max - x1_min) * (y1_max - y1_min)
        bbox2_area = (x2_max - x2_min) * (y2_max - y2_min)
        
        # 합집합 면적
        union_area = bbox1_area + bbox2_area - inter_area
        
        # IOU 계산
        if union_area == 0:
            return 0.0
        
        return inter_area / union_area
    
    def _remove_overlapping_detections(self, detections: List[Dict], iou_threshold: float = 0.5) -> List[Dict]:
        """
        같은 클래스의 겹치는 검출 중 더 높은 신뢰도를 가진 것만 남김
        
        Args:
            detections: 검출 결과 리스트
            iou_threshold: IOU 임계값 (이 값 이상이면 겹침으로 간주)
        
        Returns:
            필터링된 검출 결과 리스트
        """
        if not detections:
            return detections
        
        # 클래스별로 그룹화
        class_groups = {}
        for det in detections:
            class_name = det.get('class_name', 'unknown')
            if class_name not in class_groups:
                class_groups[class_name] = []
            class_groups[class_name].append(det)
        
        filtered_detections = []
        
        # 각 클래스별로 처리
        for class_name, class_dets in class_groups.items():
            if len(class_dets) == 1:
                # 검출이 1개만 있으면 그대로 추가
                filtered_detections.append(class_dets[0])
                continue
            
            # 신뢰도 순으로 정렬 (높은 순)
            sorted_dets = sorted(class_dets, key=lambda x: x.get('confidence', 0.0), reverse=True)
            
            # NMS 적용
            kept = []
            for i, det in enumerate(sorted_dets):
                is_overlapping = False
                bbox1 = det['bbox']
                
                # 이미 선택된 박스들과 겹치는지 확인
                for kept_det in kept:
                    bbox2 = kept_det['bbox']
                    iou = self._calculate_iou(bbox1, bbox2)
                    
                    if iou >= iou_threshold:
                        # 겹치는 경우, 더 높은 신뢰도를 가진 것만 유지
                        if det['confidence'] > kept_det['confidence']:
                            # 현재 박스가 더 높은 신뢰도를 가지면 기존 것을 제거하고 현재 것을 추가
                            kept.remove(kept_det)
                            kept.append(det)
                        is_overlapping = True
                        break
                
                # 겹치지 않으면 추가
                if not is_overlapping:
                    kept.append(det)
            
            filtered_detections.extend(kept)
        
        return filtered_detections
    
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
    
    def route_infer_single_image(self, image_path: str) -> Dict:
        """
        단일 이미지에 대해 라우팅 추론 수행
        순서: 큰 객체 탐지 -> 작은 객체 탐지
        """
        # 1. 큰 객체 모델 추론 (먼저 실행)
        print(f"  🔍 큰 객체 탐지 중...")
        large_results = self.large_model(
            str(image_path), 
            imgsz=1280, 
            conf=self.large_conf, 
            device='cpu',  # CPU 사용
            verbose=False
        )[0]
        large_detections = self.get_all_detections(large_results, self.large_class_names)
        
        # 2. 작은 객체 모델 추론
        print(f"  🔍 작은 객체 탐지 중...")
        small_results = self.small_model(
            str(image_path), 
            imgsz=2048, 
            conf=self.small_conf, 
            device='cpu',  # CPU 사용
            verbose=False
        )[0]
        small_detections = self.get_all_detections(small_results, self.small_class_names)
        
        # 결과 병합 (큰 객체 먼저)
        all_detections = large_detections + small_detections
        
        # 같은 클래스의 겹치는 검출 제거 (더 높은 신뢰도만 유지)
        filtered_detections = self._remove_overlapping_detections(all_detections, self.iou_threshold)
        
        return {
            'image_path': str(image_path),
            'detections': filtered_detections,
            'large_detections': large_detections,
            'small_detections': small_detections,
            'timestamp': datetime.now().isoformat()
        }


def process_test_dataset(
    model_dir: str,
    test_data_root: str,
    output_dir: str,
    run_post_processing: bool = True
):
    """
    테스트 데이터셋에 대해 전체 파이프라인 실행
    
    Args:
        model_dir: 모델 디렉토리 경로
        test_data_root: 테스트 데이터 루트 경로
        output_dir: 출력 디렉토리 경로
        run_post_processing: 후처리 실행 여부
    """
    # 경로 설정
    test_data_path = Path(test_data_root)
    output_path = Path(output_dir)
    
    # 출력 디렉토리 생성 (후처리 결과만)
    if run_post_processing:
        (output_path / "post_processed_results").mkdir(parents=True, exist_ok=True)
        (output_path / "post_processed_results" / "annotations").mkdir(parents=True, exist_ok=True)
        (output_path / "post_processed_results" / "images").mkdir(parents=True, exist_ok=True)
    
    # 임시 디렉토리 생성 (후처리를 위한 임시 추론 결과 저장용)
    import tempfile
    temp_dir = Path(tempfile.mkdtemp(prefix="inference_temp_"))
    
    # 라우팅 추론 초기화
    router = RoutedInference(model_dir)
    
    # 테스트 이미지 목록 가져오기
    test_images_dir = test_data_path / "test" / "images"
    if not test_images_dir.exists():
        print(f"❌ 테스트 이미지 디렉토리를 찾을 수 없습니다: {test_images_dir}")
        return
    
    image_extensions = ['.jpg', '.jpeg', '.png', '.bmp']
    image_files = []
    for ext in image_extensions:
        image_files.extend(test_images_dir.glob(f"*{ext}"))
        image_files.extend(test_images_dir.glob(f"*{ext.upper()}"))
    
    image_files = sorted(image_files)
    print(f"\n📊 테스트 이미지 {len(image_files)}개 발견\n")
    
    success_count = 0
    error_count = 0
    
    for idx, image_path in enumerate(image_files, 1):
        try:
            print(f"[{idx}/{len(image_files)}] 처리 중: {image_path.name}")
            
            # 1. 라우팅 추론 실행
            result = router.route_infer_single_image(str(image_path))
            
            # 출력 억제를 위해 임시로 stdout 리다이렉트
            import io
            import contextlib
            f = io.StringIO()
            
            # 2. 후처리 실행 (옵션)
            if run_post_processing:
                print(f"  🔧 후처리 실행 중...")
                json_filename = image_path.stem + ".json"
                
                # 임시 추론 결과 저장 (후처리 함수가 JSON 파일 경로를 요구)
                temp_inference_json_path = temp_dir / json_filename
                with open(temp_inference_json_path, "w", encoding="utf-8") as f_temp:
                    json.dump(result, f_temp, ensure_ascii=False, indent=2)
                
                # 후처리 실행
                post_processed_json_path = output_path / "post_processed_results" / "annotations" / json_filename
                with contextlib.redirect_stdout(f):
                    post_processing(
                        str(temp_inference_json_path),
                        str(image_path),
                        str(post_processed_json_path)
                    )
                
                # 후처리 결과 시각화
                post_processed_viz_path = output_path / "post_processed_results" / "images" / (image_path.stem + ".jpg")
                with contextlib.redirect_stdout(f):
                    visualize_detections(str(image_path), str(post_processed_json_path), str(post_processed_viz_path))
                
                # 임시 파일 삭제
                temp_inference_json_path.unlink()
            
            print(f"  ✅ 완료\n")
            success_count += 1
            
        except Exception as e:
            print(f"  ❌ 오류 발생: {str(e)}\n")
            import traceback
            traceback.print_exc()
            error_count += 1
    
    # 임시 디렉토리 삭제
    import shutil
    if temp_dir.exists():
        shutil.rmtree(temp_dir)
    
    print("=" * 80)
    print(f"처리 완료: 성공 {success_count}개, 실패 {error_count}개")
    if run_post_processing:
        print(f"결과 저장 위치:")
        print(f"  - 후처리 결과: {output_path / 'post_processed_results'}")
    print("=" * 80)
    
    # 평가 수행 (후처리 결과만)
    if success_count > 0 and run_post_processing:
        print("\n📊 평가 수행 중...")
        evaluate_results(
            test_data_path=test_data_path,
            results_dir=output_path / "post_processed_results" / "annotations",
            output_dir=output_path / "evaluation_post_processed"
        )


def evaluate_results(test_data_path: Path, results_dir: Path, output_dir: Path):
    """
    추론 결과를 평가합니다.
    
    Args:
        test_data_path: 테스트 데이터 루트 경로
        results_dir: 추론 결과 JSON 파일 디렉토리
        output_dir: 평가 결과 출력 디렉토리
    """
    from collections import defaultdict
    
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # 클래스 이름 매핑 (YOLO 클래스 ID -> 이름)
    class_id_to_name = {
        0: '1', 1: '2', 2: '3', 3: '4', 4: '5',
        5: 'answer_1', 6: 'answer_2', 7: 'answer_option',
        8: 'english_content', 9: 'korean_content',
        10: 'page_number', 11: 'problem_number', 12: 'section'
    }
    
    # 통계 수집
    class_counts = defaultdict(int)
    total_detections = 0
    total_images = 0
    confidence_sum = 0.0
    
    # JSON 파일 처리
    json_files = sorted(results_dir.glob("*.json"))
    
    for json_file in json_files:
        try:
            with open(json_file, "r", encoding="utf-8") as f:
                data = json.load(f)
            
            detections = data.get('detections', [])
            total_images += 1
            
            for det in detections:
                class_name = det.get('class_name', 'unknown')
                confidence = det.get('confidence', 0.0)
                
                class_counts[class_name] += 1
                total_detections += 1
                confidence_sum += confidence
                
        except Exception as e:
            print(f"  ⚠️ JSON 파일 처리 오류: {json_file.name} - {str(e)}")
    
    # 결과 저장
    results_summary = {
        'total_images': total_images,
        'total_detections': total_detections,
        'average_detections_per_image': total_detections / total_images if total_images > 0 else 0,
        'average_confidence': confidence_sum / total_detections if total_detections > 0 else 0,
        'class_counts': dict(class_counts)
    }
    
    # JSON으로 저장
    summary_path = output_dir / "results_summary.json"
    with open(summary_path, "w", encoding="utf-8") as f:
        json.dump(results_summary, f, ensure_ascii=False, indent=2)
    
    # 텍스트 요약 출력
    print("\n" + "=" * 80)
    print("📊 평가 결과 요약")
    print("=" * 80)
    print(f"총 이미지 수: {total_images}")
    print(f"총 검출 수: {total_detections}")
    print(f"이미지당 평균 검출 수: {results_summary['average_detections_per_image']:.2f}")
    print(f"평균 신뢰도: {results_summary['average_confidence']:.3f}")
    print("\n클래스별 검출 수:")
    for class_name, count in sorted(class_counts.items()):
        print(f"  - {class_name}: {count}")
    print(f"\n결과 저장: {summary_path}")
    print("=" * 80)


def main():
    """메인 함수"""
    import argparse
    
    parser = argparse.ArgumentParser(description="라우팅 추론 및 평가")
    parser.add_argument("--model_dir", type=str, 
                       default=str(Path(__file__).parent / "models"),
                       help="모델 디렉토리 경로")
    parser.add_argument("--test_data", type=str,
                       default=str(Path(__file__).parent.parent.parent / "Data" / "temp_extract_251104"),
                       help="테스트 데이터 루트 경로")
    parser.add_argument("--output_dir", type=str,
                       default=str(Path(__file__).parent / "results"),
                       help="출력 디렉토리 경로")
    parser.add_argument("--no_post_processing", action="store_true",
                       help="후처리 건너뛰기")
    
    args = parser.parse_args()
    
    process_test_dataset(
        model_dir=args.model_dir,
        test_data_root=args.test_data,
        output_dir=args.output_dir,
        run_post_processing=not args.no_post_processing
    )


if __name__ == "__main__":
    main()