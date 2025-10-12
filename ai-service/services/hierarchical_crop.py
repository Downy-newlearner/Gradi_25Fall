# 계층적 크롭 파이프라인
## 순차 처리 페이지 번호 → Section → 문제 번호 및 정답

import logging
from pathlib import Path
from typing import Dict, List, Tuple
import cv2
import numpy as np
from models.Detection.Model_routing_1004.run_routed_inference import RoutedInference
from models.Recognition.ocr import EasyOCRModel

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class HierarchicalCropPipeline:
    """계층적 크롭 파이프라인: 페이지 → Section → 문제번호 및 정답"""
    
    def __init__(self, model_dir: str):
        self.router = RoutedInference(model_dir)
        logger.info("HierarchicalCropPipeline 초기화")
    
    def crop_page_number(self, image_path: str, detections: List[Dict], output_dir: Path) -> str:
        image = cv2.imread(image_path)
        if image is None:
            logger.error(f"이미지 로드 실패: {image_path}")
            return None
        
        page_num_detections = [d for d in detections if d['class_name'] == 'page_number']
        
        if not page_num_detections:
            logger.warning(f"페이지 번호 미검출: {image_path}")
            return None
        
        # 신뢰도 가장 높은 것 선택
        best_det = max(page_num_detections, key=lambda x: x['confidence'])
        x1, y1, x2, y2 = map(int, best_det['bbox'])
        
        h, w = image.shape[:2]
        x1, y1 = max(0, x1), max(0, y1)
        x2, y2 = min(w, x2), min(h, y2)
        
        if x2 <= x1 or y2 <= y1:
            logger.warning(f"잘못된 페이지 번호 박스: {best_det['bbox']}")
            return None
        
        # 크롭 및 저장
        cropped = image[y1:y2, x1:x2]
        page_num_dir = output_dir / "page_numbers"
        page_num_dir.mkdir(parents=True, exist_ok=True)
        
        image_name = Path(image_path).stem
        save_path = page_num_dir / f"{image_name}_page_number.jpg"
        cv2.imwrite(str(save_path), cropped)
        
        logger.info(f"페이지 번호 crop 완료: {save_path}")
        return str(save_path)
    

    def process_single_section(self, original_image_path: str, section_idx: int, 
                               page_name: str, output_dir: Path, 
                               section_bbox: List[float], all_detections: List[Dict]) -> Dict:
        
        # 해당 section 내부에 있는 문제번호 및 정답만 필터링
        sx1, sy1, sx2, sy2 = section_bbox
        detections = []
        
        for det in all_detections:
            dx1, dy1, dx2, dy2 = det['bbox']

            center_x = (dx1 + dx2) / 2
            center_y = (dy1 + dy2) / 2
            
            if sx1 <= center_x <= sx2 and sy1 <= center_y <= sy2:
                if det['class_name'] in ['problem_number', 'answer_1', 'answer_2']:
                    detections.append(det)
        
        # 원본 페이지 이미지 로드
        image = cv2.imread(original_image_path)
        if image is None:
            logger.error(f"원본 이미지 로드 실패: {original_image_path}")
            return {}
        
        section_result = {
            'section_idx': section_idx,
            'problem_numbers': [],
            'answers': []
        }
        
        section_output_dir = output_dir / page_name / f"section_{section_idx:02d}"
        section_output_dir.mkdir(parents=True, exist_ok=True)
        
        # 문제 번호 crop
        problem_num_dets = [d for d in detections if d['class_name'] == 'problem_number']
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
            section_result['problem_numbers'].append(str(save_path))
        
        # 정답 crop (answer_1, answer_2)
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
        
        logger.info(f"Section {section_idx} 처리 완료: 문제번호 {len(section_result['problem_numbers'])}개, 정답 {len(section_result['answers'])}개")
        return section_result
    
    def process_page(self, image_path: str, output_dir: Path) -> Dict:
        """전체 파이프라인(한 페이지 처리)"""

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
            'sections': []
        }
        
        # 1단계: 페이지 번호 crop
        logger.info("\n1. 페이지 번호 crop")
        page_num_path = self.crop_page_number(image_path, detections, page_output_dir)
        page_result['page_number_path'] = page_num_path
        
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
        
        # 3-4단계: 각 Section 처리
        logger.info("\n3. 각 Section에서 문제번호 및 정답 crop")
        for section_path, section_idx, section_bbox in section_info:
            section_result = self.process_single_section(
                image_path, section_idx, page_name, output_dir,
                section_bbox, detections
            )
            page_result['sections'].append(section_result)

        logger.info(f"\n페이지 '{page_name}' 처리 완료")
        logger.info(f"  - 페이지 번호: {page_num_path}")
        logger.info(f"  - Section 수: {len(section_info)}")
        logger.info(f"  - 출력 디렉토리: {page_output_dir}")
        
        return page_result


def main():

    current_dir = Path(__file__).parent
    
    input_images_dir = current_dir.parent / "recognition" / "exp_images"
    output_dir = current_dir / "hierarchical_results"
    model_dir = current_dir / "Model_routing_1004"
    
    logger.info("계층적 크롭 파이프라인 시작")
    logger.info(f"입력 디렉토리: {input_images_dir}")
    logger.info(f"출력 디렉토리: {output_dir}")
    logger.info(f"모델 디렉토리: {model_dir}")
    
    pipeline = HierarchicalCropPipeline(str(model_dir))
    
    image_extensions = ['.jpg', '.jpeg', '.png', '.bmp']
    image_files = []
    for ext in image_extensions:
        image_files.extend(input_images_dir.glob(f"*{ext}"))
        image_files.extend(input_images_dir.glob(f"*{ext.upper()}"))
    
    image_files = sorted(image_files)
    logger.info(f"\n처리할 이미지: {len(image_files)}개")

    # 각 이미지 처리
    all_results = []
    for idx, image_path in enumerate(image_files):
        logger.info(f"\n\n[{idx+1}/{len(image_files)}] 처리")
        result = pipeline.process_page(str(image_path), output_dir)
        all_results.append(result)
    
    logger.info("\n\n" + "="*60)
    logger.info("전체 처리 결과 요약")
    logger.info("="*60)
    
    total_sections = sum(len(r['sections']) for r in all_results)
    logger.info(f"처리된 페이지: {len(all_results)}개")
    logger.info(f"총 Section 수: {total_sections}개")
    logger.info(f"출력 위치: {output_dir}")

    logger.info("\n모든 작업이 완료되었습니다.")


if __name__ == "__main__":
    main()