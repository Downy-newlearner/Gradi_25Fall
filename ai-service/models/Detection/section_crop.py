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
    """Raw 이미지 예측 및 section 크롭을 수행하는 클래스."""
    
    def __init__(self, model_path: str, class_names: List[str]):
        """
        SectionPredictor 초기화.
        
        Args:
            model_path: 훈련된 YOLO 모델 파일 경로
            class_names: 클래스 이름 리스트
        """
        self.model = YOLO(model_path)
        self.class_names = class_names
        self.section_class_id = class_names.index('section') if 'section' in class_names else None
        
        if self.section_class_id is None:
            raise ValueError("'section' 클래스가 class_names에 없습니다.")
        
        logger.info(f"모델 로드 완료: {model_path}")
        logger.info(f"Section 클래스 ID: {self.section_class_id}")
    
    def predict_images(self, image_paths: List[Path], output_dir: Path) -> Dict[str, List[Dict]]:
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
        
        logger.info(f"총 {len(image_paths)}개 이미지에 대해 예측을 시작합니다.")
        
        for i, image_path in enumerate(image_paths):
            logger.info(f"처리 중 ({i+1}/{len(image_paths)}): {image_path.name}")
            
            try:
                # 예측 실행
                results = self.model(str(image_path))
                result = results[0]
                
                # 예측 결과 저장
                pred_data = {
                    'boxes': result.boxes.xyxy.cpu().numpy() if result.boxes is not None else np.array([]),
                    'scores': result.boxes.conf.cpu().numpy() if result.boxes is not None else np.array([]),
                    'classes': result.boxes.cls.cpu().numpy() if result.boxes is not None else np.array([]),
                    'image_path': str(image_path)
                }
                predictions[str(image_path)] = pred_data
                
                # 시각화 결과 저장
                vis_path = output_dir / f"prediction_{image_path.stem}.jpg"
                result.save(str(vis_path))
                
                logger.debug(f"예측 완료: {image_path.name} -> {vis_path.name}")
                
            except Exception as e:
                logger.error(f"예측 실패 - {image_path.name}: {e}")
                continue
        
        logger.info(f"예측 완료. 시각화 결과가 {output_dir}에 저장되었습니다.")
        return predictions
    
    def crop_sections(self, predictions: Dict[str, List[Dict]], output_dir: Path) -> None:
        """
        Section 검출 결과를 기반으로 이미지를 크롭.
        
        Args:
            predictions: 예측 결과 딕셔너리
            output_dir: 크롭된 이미지를 저장할 디렉토리
        """
        output_dir.mkdir(parents=True, exist_ok=True)
        
        total_sections = 0
        processed_images = 0
        
        for image_path_str, pred_data in predictions.items():
            image_path = Path(image_path_str)
            
            # Section 클래스만 필터링
            if len(pred_data['classes']) == 0:
                logger.debug(f"검출 결과 없음: {image_path.name}")
                continue
                
            section_mask = pred_data['classes'] == self.section_class_id
            section_boxes = pred_data['boxes'][section_mask]
            section_scores = pred_data['scores'][section_mask]
            
            if len(section_boxes) == 0:
                logger.debug(f"Section 미검출: {image_path.name}")
                continue
            
            logger.info(f"처리 중: {image_path.name} - {len(section_boxes)}개 section 검출")
            
            try:
                # 원본 이미지 로드
                image = cv2.imread(str(image_path))
                if image is None:
                    logger.error(f"이미지 로드 실패: {image_path}")
                    continue
                
                # 각 section별로 크롭
                for j, (box, score) in enumerate(zip(section_boxes, section_scores)):
                    x1, y1, x2, y2 = box.astype(int)
                    
                    # 경계 검사
                    h, w = image.shape[:2]
                    x1, y1 = max(0, x1), max(0, y1)
                    x2, y2 = min(w, x2), min(h, y2)
                    
                    if x2 <= x1 or y2 <= y1:
                        logger.warning(f"잘못된 박스 좌표: {box}")
                        continue
                    
                    # 크롭 수행
                    cropped = image[y1:y2, x1:x2]
                    
                    # 파일명 생성 (출처 추적 가능)
                    source_name = image_path.stem
                    crop_filename = f"{source_name}_section_{j:02d}_conf{score:.2f}.jpg"
                    crop_path = output_dir / crop_filename
                    
                    # 크롭된 이미지 저장
                    cv2.imwrite(str(crop_path), cropped)
                    logger.debug(f"Section 크롭 저장: {crop_filename}")
                    
                    total_sections += 1
                
                processed_images += 1
                
            except Exception as e:
                logger.error(f"크롭 실패 - {image_path.name}: {e}")
                continue
        
        logger.info(f"크롭 완료: {processed_images}개 이미지에서 {total_sections}개 section 추출")

def main() -> None:
    """메인 실행 함수."""
    # 경로 설정 - 현재 스크립트 위치 기준
    current_dir = Path(__file__).parent
    model_path = current_dir / "yolov8l_best_0904.pt"
    raws_dir = current_dir.parent / "recognition" / "exp_images"
    
    # 출력 디렉토리 설정
    predictions_output_dir = current_dir / "predictions_visualization"
    sections_output_dir = current_dir / "sections"
    
    # 클래스 이름 (data.yaml에서 확인한 순서대로)
    class_names = ['answer', 'page', 'question_number', 'section', 'sub_question_number']
    
    logger.info("=== Raw 이미지 예측 및 Section 크롭 시작 ===")
    
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
    
    # SectionPredictor 초기화
    predictor = SectionPredictor(str(model_path), class_names)
    
    # 1단계: 예측 실행 및 시각화
    logger.info("1단계: 예측 실행 및 시각화 저장")
    predictions = predictor.predict_images(image_paths, predictions_output_dir)
    
    # 2단계: Section 기반 크롭
    logger.info("2단계: Section 기반 이미지 크롭")
    predictor.crop_sections(predictions, sections_output_dir)
    
    logger.info("=== 모든 작업 완료 ===")
    logger.info(f"시각화 결과: {predictions_output_dir}")
    logger.info(f"크롭된 Section 이미지: {sections_output_dir}")

if __name__ == "__main__":
    main()
