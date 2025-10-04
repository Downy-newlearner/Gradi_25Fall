from __future__ import annotations
import sys
import json
import logging
from pathlib import Path
from typing import List, Dict
import cv2
import numpy as np
from ultralytics import YOLO

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# 클래스 라우팅 정의
SMALL_CLASSES = {"page_number", "problem_number", "answer_1", "answer_2"}
LARGE_CLASSES = {"korean_content", "english_content", "section", "answer_option"}

ROOT = Path(__file__).resolve().parent
S_DIR = ROOT / "yolov8s_imgsz_2048"
N_DIR = ROOT / "yolov8n_imgsz_1280"

# 출력 디렉토리
OUTPUT_DIR = ROOT / "inference_test_routing_0930"
VIS_DIR = OUTPUT_DIR / "visualizations"
JSON_DIR = OUTPUT_DIR / "predictions"

# 가중치 경로: 없으면 기본 pt 사용
S_WEIGHTS = (S_DIR / "train" / "weights" / "best.pt")
N_WEIGHTS = (N_DIR / "train" / "weights" / "best.pt")

s_model = YOLO(str(S_WEIGHTS if S_WEIGHTS.exists() else "yolov8s.pt"))
n_model = YOLO(str(N_WEIGHTS if N_WEIGHTS.exists() else "yolov8n.pt"))

# 추론 파라미터
S_CONF = 0.22
N_CONF = 0.12


def route_infer(images: List[str]) -> Dict[str, Dict[str, list]]:
    """라우팅 기반 추론 수행."""
    logger.info(f"Starting inference on {len(images)} images")
    s_preds = s_model.predict(source=images, imgsz=2048, conf=S_CONF, device='cpu', verbose=False)
    n_preds = n_model.predict(source=images, imgsz=1280, conf=N_CONF, device='cpu', verbose=False)

    results: Dict[str, Dict[str, list]] = {}
    for img_path, sp, np in zip(images, s_preds, n_preds):
        merged = []
        # 작은 클래스만 s에서 취합
        for b in sp.boxes:
            cls_name = sp.names[int(b.cls.item())]
            if cls_name in SMALL_CLASSES:
                merged.append({
                    "cls": cls_name,
                    "conf": float(b.conf.item()),
                    "xyxy": [float(x) for x in b.xyxy[0].tolist()],
                })
        # 큰 클래스만 n에서 취합
        for b in np.boxes:
            cls_name = np.names[int(b.cls.item())]
            if cls_name in LARGE_CLASSES:
                merged.append({
                    "cls": cls_name,
                    "conf": float(b.conf.item()),
                    "xyxy": [float(x) for x in b.xyxy[0].tolist()],
                })
        results[img_path] = {"detections": merged}
    return results


def visualize_results(image_path: str, detections: List[Dict], output_path: Path) -> None:
    """검출 결과 시각화."""
    img = cv2.imread(image_path)
    if img is None:
        logger.error(f"Failed to load image: {image_path}")
        return

    # 클래스별 색상 정의
    color_map = {
        "page_number": (255, 0, 0),      # 파랑
        "problem_number": (0, 255, 0),   # 초록
        "answer_1": (0, 0, 255),         # 빨강
        "answer_2": (255, 255, 0),       # 시안
        "korean_content": (255, 0, 255), # 마젠타
        "english_content": (0, 255, 255),# 노랑
        "section": (128, 0, 128),        # 보라
        "answer_option": (255, 165, 0),  # 주황
    }

    for det in detections:
        x1, y1, x2, y2 = [int(v) for v in det["xyxy"]]
        cls_name = det["cls"]
        conf = det["conf"]
        color = color_map.get(cls_name, (255, 255, 255))

        # 박스 그리기
        cv2.rectangle(img, (x1, y1), (x2, y2), color, 2)

        # 레이블 그리기
        label = f"{cls_name}: {conf:.2f}"
        (text_width, text_height), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 1)
        cv2.rectangle(img, (x1, y1 - text_height - 4), (x1 + text_width, y1), color, -1)
        cv2.putText(img, label, (x1, y1 - 2), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)

    cv2.imwrite(str(output_path), img)
    logger.info(f"Visualization saved: {output_path}")


def save_predictions(results: Dict[str, Dict[str, list]], output_path: Path) -> None:
    """예측 결과를 JSON 파일로 저장."""
    # 경로를 상대 경로로 변환
    simplified_results = {}
    for img_path, data in results.items():
        img_name = Path(img_path).name
        simplified_results[img_name] = data

    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(simplified_results, f, indent=2, ensure_ascii=False)
    logger.info(f"Predictions saved: {output_path}")


if __name__ == "__main__":
    # 출력 디렉토리 생성
    VIS_DIR.mkdir(parents=True, exist_ok=True)
    JSON_DIR.mkdir(parents=True, exist_ok=True)
    
    # exp_images 폴더에서 이미지 수집 (하위 디렉토리 제외)
    exp_images_dir = ROOT.parent.parent / "recognition" / "exp_images"
    logger.info(f"Searching for images in: {exp_images_dir}")
    
    image_extensions = {'.jpg', '.jpeg', '.png', '.bmp'}
    image_paths = []
    
    for file in exp_images_dir.iterdir():
        if file.is_file() and file.suffix.lower() in image_extensions:
            image_paths.append(str(file))
    
    if not image_paths:
        logger.error("No images found in exp_images directory")
        sys.exit(1)
    
    logger.info(f"Found {len(image_paths)} images")
    
    # 추론 실행
    results = route_infer(image_paths)
    
    # 시각화 생성
    logger.info("Generating visualizations...")
    for img_path, data in results.items():
        img_name = Path(img_path).stem
        vis_output = VIS_DIR / f"{img_name}_routed.jpg"
        visualize_results(img_path, data["detections"], vis_output)
    
    # 예측 결과 저장
    json_output = JSON_DIR / "predictions.json"
    save_predictions(results, json_output)
    
    # 통계 출력
    logger.info("\n=== Inference Summary ===")
    total_detections = 0
    for img_path, data in results.items():
        img_name = Path(img_path).name
        num_dets = len(data["detections"])
        total_detections += num_dets
        logger.info(f"{img_name}: {num_dets} detections")
    
    logger.info(f"\nTotal images processed: {len(results)}")
    logger.info(f"Total detections: {total_detections}")
    logger.info(f"Average detections per image: {total_detections/len(results):.2f}")
    logger.info(f"\nResults saved to: {OUTPUT_DIR}")


