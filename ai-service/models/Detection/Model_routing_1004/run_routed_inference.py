#!/usr/bin/env python3
"""
라우팅 추론 스크립트
YOLOv8n (큰 객체)과 YOLOv8s (작은 객체) 모델을 결합하여 추론을 수행합니다.
각 클래스별로 가장 높은 신뢰도의 바운딩박스만 선택합니다.
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

# 클래스 라우팅 정의
SMALL_CLASSES = {"page_number", "problem_number", "answer_1", "answer_2"}
LARGE_CLASSES = {"korean_content", "english_content", "section", "answer_option"}

# 클래스별 색상 정의
CLASS_COLORS = {
    # 큰 객체 클래스
    'answer_option': (0, 255, 0),      # 녹색
    'english_content': (255, 0, 0),    # 빨간색
    'korean_content': (0, 0, 255),     # 파란색
    'section': (255, 255, 0),          # 노란색
    
    # 작은 객체 클래스
    'page_number': (255, 0, 255),      # 마젠타
    'problem_number': (0, 255, 255),   # 시안
    'answer_1': (255, 165, 0),         # 오렌지
    'answer_2': (128, 0, 128)          # 보라
}

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
        모든 검출 결과를 반환 (클래스별 최고 신뢰도 선택 제거)
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
        """
        # 작은 객체 모델 추론 (YOLOv8s @ 2048)
        small_results = self.small_model(str(image_path), imgsz=2048, conf=self.small_conf, verbose=False)[0]
        small_class_names = ['page_number', 'problem_number', 'answer_1', 'answer_2']
        small_detections = self.get_all_detections(small_results, small_class_names)
        
        # 큰 객체 모델 추론 (YOLOv8n @ 1280)
        large_results = self.large_model(str(image_path), imgsz=1280, conf=self.large_conf, verbose=False)[0]
        large_class_names = ['answer_option', 'english_content', 'korean_content', 'section']
        large_detections = self.get_all_detections(large_results, large_class_names)
        
        # 결과 병합
        all_detections = small_detections + large_detections
        
        return {
            'image_path': str(image_path),
            'detections': all_detections,
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
            
            # 바운딩 박스 그리기
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
        print(f"📊 테스트 이미지 {len(image_files)}개 발견")
        
        # 결과 저장용
        all_results = []
        total_detections = 0
        class_counts = {name: 0 for name in CLASS_COLORS.keys()}
        total_confidence = 0
        
        print(f"🔍 {len(image_files)}개 이미지에 대해 라우팅 추론 시작...")
        
        for i, image_path in enumerate(image_files):
            print(f"처리 중: {i+1}/{len(image_files)} - {image_path.name}")
            
            # 라우팅 추론 수행
            result = self.route_infer_single_image(str(image_path))
            all_results.append(result)
            
            # 시각화 이미지 저장
            output_image_path = output_path / "images" / f"routed_result_{image_path.stem}.jpg"
            self.visualize_detections(str(image_path), result['detections'], str(output_image_path))
            
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
            }
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
        print("\n📈 클래스별 검출 수:")
        for class_name, count in summary['class_counts'].items():
            print(f"  - {class_name}: {count}")
        
        print(f"\n✅ 결과 저장 완료: {output_path}")
        print(f"  - 시각화 이미지: {output_path}/images/")
        print(f"  - 검출 데이터: {output_path}/annotations/")
        print(f"  - 결과 요약: {output_path}/routing_results_summary.json")
        
        return summary


def main():
    # 경로 설정
    current_dir = Path(__file__).parent
    test_data_root = current_dir.parent.parent / "Data" / "english_large4_251004"  # 테스트용
    output_dir = current_dir / "routed_inference_results"
    
    print("🚀 라우팅 추론 시작")
    print(f"📁 테스트 데이터: {test_data_root}")
    print(f"📁 출력 디렉토리: {output_dir}")
    print("=" * 60)
    
    try:
        # 라우팅 추론 실행
        router = RoutedInference(str(current_dir))
        results = router.process_test_images(str(test_data_root), str(output_dir))
        
        print("✅ 라우팅 추론 완료!")
        
    except Exception as e:
        print(f"❌ 오류 발생: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0


if __name__ == "__main__":
    exit(main())