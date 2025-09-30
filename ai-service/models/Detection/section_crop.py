#!/usr/bin/env python3
"""
Raw 이미지에 대한 예측 실행 및 section 기반 크롭 스크립트.

이 스크립트는 다음 작업을 수행합니다:
1. raws 폴더의 모든 이미지에 대해 YOLOv8 모델로 예측 실행
2. 예측 결과를 시각화하여 저장
3. section 클래스의 검출 결과를 기반으로 이미지 크롭
4. 크롭된 section 이미지들을 저장
"""

from __future__ import annotations

import logging
import os
from pathlib import Path
from typing import Dict, List, Tuple

import cv2
import numpy as np
from ultralytics import YOLO

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class SectionPredictor:
    """Raw 이미지 예측 및 클래스 기반 크롭을 수행하는 클래스."""

    def __init__(self, model_path: str, class_names: List[str]):
        """
        SectionPredictor 초기화.
        
        Args:
            model_path: 훈련된 YOLO 모델 파일 경로
            class_names: 클래스 이름 리스트
        """
        self.model = YOLO(model_path)
        self.class_names = class_names
        self.class_ids = {name: idx for idx, name in enumerate(class_names)}

        if not self.class_ids:
            raise ValueError("class_names가 비어있습니다.")

        logger.info(f"모델 로드 완료: {model_path}")
        logger.info(f"클래스 ID 매핑: {self.class_ids}")

    def predict_images(self, image_paths: List[Path], output_dir: Path) -> Dict[str, Dict]:
        """
        이미지들에 대해 예측을 실행하고 결과를 저장.
        
        Args:
            image_paths: 예측할 이미지 경로 리스트
            output_dir: 시각화 결과를 저장할 디렉토리
            
        Returns:
            각 이미지별 예측 결과 딕셔너리
        """
        output_dir.mkdir(parents=True, exist_ok=True)
        predictions = {}

        logger.info(f"총 {len(image_paths)}개 이미지에 대해 예측 시작")

        for i, image_path in enumerate(image_paths):
            logger.info(f"처리 중 ({i+1}/{len(image_paths)}): {image_path.name}")
            try:
                results = self.model(str(image_path), 
                                   imgsz=2048,      # 이미지 크기
                                   conf=0.25,       # 신뢰도 임계값
                                   iou=0.7,         # IoU 임계값 (중복 제거)
                                   max_det=300)     # 최대 검출 수
                result = results[0]

                pred_data = {
                    'boxes': result.boxes.xyxy.cpu().numpy() if result.boxes is not None else np.array([]),
                    'scores': result.boxes.conf.cpu().numpy() if result.boxes is not None else np.array([]),
                    'classes': result.boxes.cls.cpu().numpy() if result.boxes is not None else np.array([]),
                    'image_path': str(image_path)
                }
                predictions[str(image_path)] = pred_data

                # 시각화 저장
                vis_path = output_dir / f"prediction_{image_path.stem}.jpg"
                result.save(str(vis_path))

            except Exception as e:
                logger.error(f"예측 실패 - {image_path.name}: {e}")
                continue

        logger.info(f"예측 완료. 시각화 결과 저장: {output_dir}")
        return predictions

    def crop_sections(self, predictions: Dict[str, Dict], output_dir: Path) -> None:
        """
        모든 클래스 검출 결과를 기반으로 이미지를 크롭.
        페이지별 + 클래스별 폴더 구조 생성.
        
        Args:
            predictions: 예측 결과 딕셔너리
            output_dir: 크롭된 이미지를 저장할 디렉토리
        """
        output_dir.mkdir(parents=True, exist_ok=True)

        total_crops = 0
        processed_images = 0

        for image_path_str, pred_data in predictions.items():
            image_path = Path(image_path_str)
            image = cv2.imread(str(image_path))
            if image is None:
                logger.error(f"이미지 로드 실패: {image_path}")
                continue

            # 페이지별 폴더 생성
            page_dir = output_dir / image_path.stem
            page_dir.mkdir(parents=True, exist_ok=True)

            for label, class_id in self.class_ids.items():
                mask = pred_data['classes'] == class_id
                boxes = pred_data['boxes'][mask]
                scores = pred_data['scores'][mask]

                if len(boxes) == 0:
                    continue

                # 클래스별 하위 폴더 생성
                class_dir = page_dir / label
                class_dir.mkdir(exist_ok=True, parents=True)

                for j, (box, score) in enumerate(zip(boxes, scores)):
                    x1, y1, x2, y2 = box.astype(int)

                    # 경계 검사
                    h, w = image.shape[:2]
                    x1, y1 = max(0, x1), max(0, y1)
                    x2, y2 = min(w, x2), min(h, y2)

                    if x2 <= x1 or y2 <= y1:
                        logger.warning(f"잘못된 박스 좌표: {box}")
                        continue

                    cropped = image[y1:y2, x1:x2]
                    crop_filename = f"{label}_{j:02d}_conf{score:.2f}.jpg"
                    cv2.imwrite(str(class_dir / crop_filename), cropped)
                    total_crops += 1

            processed_images += 1

        logger.info(f"크롭 완료: {processed_images}개 이미지에서 총 {total_crops}개 객체 추출")

def main() -> None:
    """메인 실행 함수."""
    current_dir = Path(__file__).parent
    model_path = current_dir / "0930_english_best_detection_yolov8n.pt"
    raws_dir = current_dir.parent / "recognition" / "exp_images"

    predictions_output_dir = current_dir / "predictions_visualization"
    sections_output_dir = current_dir / "sections"

    class_names = ['answer_1', 'answer_2', 'answer_option', 'english_content', 'korean_content', 'page_number', 'problem_number', 'section']

    logger.info("=== Raw 이미지 예측 및 클래스 기반 크롭 시작 ===")

    # 모든 이미지 파일 수집
    image_extensions = {'.jpg', '.jpeg', '.png', '.bmp'}
    image_paths = []
    for root, dirs, files in os.walk(raws_dir):
        for file in files:
            if Path(file).suffix.lower() in image_extensions:
                image_paths.append(Path(root) / file)

    logger.info(f"총 {len(image_paths)}개 이미지 파일 발견")
    if not image_paths:
        logger.error("처리할 이미지가 없습니다.")
        return

    # 예측기 초기화
    predictor = SectionPredictor(str(model_path), class_names)

    # 1단계: 예측 + 시각화
    logger.info("1단계: 예측 실행 및 시각화 저장")
    predictions = predictor.predict_images(image_paths, predictions_output_dir)

    # 2단계: 페이지별 + 클래스별 크롭
    logger.info("2단계: 페이지별 + 클래스별 이미지 크롭")
    predictor.crop_sections(predictions, sections_output_dir)

    logger.info("=== 모든 작업 완료 ===")
    logger.info(f"시각화 결과: {predictions_output_dir}")
    logger.info(f"크롭된 이미지: {sections_output_dir}")

if __name__ == "__main__":
    main()