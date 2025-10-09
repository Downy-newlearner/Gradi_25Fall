#!/usr/bin/env python3
"""
라우팅 추론 결과를 기반으로 Section 클래스 크롭 스크립트

- run_routed_inference.py 결과를 받아 이미지 크롭
- 페이지별 + 클래스별 폴더 구조로 저장
"""

from __future__ import annotations
import logging
from pathlib import Path
from typing import Dict, List
import cv2
import numpy as np

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class SectionPredictor:
    """라우팅 추론 결과를 기반으로 이미지 크롭 수행"""

    def __init__(self, class_names: List[str]):
        """
        Args:
            class_names: 클래스 이름 리스트
        """
        self.class_names = class_names
        self.class_ids = {name: idx for idx, name in enumerate(class_names)}
        logger.info(f"SectionPredictor 초기화 완료. 클래스: {self.class_ids}")

    def load_predictions(self, routed_results: List[Dict]) -> Dict[str, Dict]:
        """
        run_routed_inference.py 결과를 crop_sections()에서 사용 가능한 형태로 변환
        """
        predictions = {}

        for res in routed_results:
            image_path = res['image_path']
            boxes = []
            scores = []
            classes = []

            for det in res['detections']:
                cls_name = det['class_name']
                if cls_name in self.class_ids:
                    boxes.append(det['bbox'])
                    scores.append(det['confidence'])
                    classes.append(self.class_ids[cls_name])

            predictions[image_path] = {
                'boxes': np.array(boxes),
                'scores': np.array(scores),
                'classes': np.array(classes),
                'image_path': image_path
            }

        logger.info(f"총 {len(predictions)}개 이미지 예측 결과 로드 완료")
        return predictions

    def crop_sections(self, predictions: Dict[str, Dict], output_dir: Path) -> None:
        """
        모든 클래스 검출 결과를 기반으로 이미지를 크롭.
        페이지별 + 클래스별 폴더 구조 생성.
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

            page_dir = output_dir / image_path.stem
            page_dir.mkdir(parents=True, exist_ok=True)

            for label, class_id in self.class_ids.items():
                mask = pred_data['classes'] == class_id
                boxes = pred_data['boxes'][mask]
                scores = pred_data['scores'][mask]

                if len(boxes) == 0:
                    continue

                class_dir = page_dir / label
                class_dir.mkdir(exist_ok=True, parents=True)

                for j, (box, score) in enumerate(zip(boxes, scores)):
                    x1, y1, x2, y2 = map(int, box)

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


def main():
    from Model_routing_1004.run_routed_inference import RoutedInference

    current_dir = Path(__file__).parent
    raws_dir = current_dir.parent / "recognition" / "exp_images" 

    predictions_output_dir = current_dir / "predictions_visualization"
    sections_output_dir = current_dir / "sections"

    class_names = ['answer_1', 'answer_2', 'answer_option', 'english_content',
                   'korean_content', 'page_number', 'problem_number', 'section']

    # 1️⃣ 라우팅 추론 수행
    router = RoutedInference(str(current_dir / "Model_routing_1004"))
    routed_results = router.process_test_images(str(raws_dir), str(current_dir / "routed_temp_results"))

    # 2️⃣ SectionPredictor 초기화 및 예측 결과 로드
    predictor = SectionPredictor(class_names)
    predictions = predictor.load_predictions(routed_results)

    # 3️⃣ 크롭 실행
    predictor.crop_sections(predictions, sections_output_dir)
    logger.info("=== 모든 작업 완료 ===")
    logger.info(f"크롭된 이미지 저장 위치: {sections_output_dir}")


if __name__ == "__main__":
    main()
