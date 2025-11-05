#!/usr/bin/env python3
"""
RoutedInference를 활용한 정답 검증 스크립트

- images/test_images/{1,2,3,4,5} 폴더 내 모든 이미지에 대해 추론 수행
- 각 이미지에서 answer_1과 가장 많이 겹치는 번호(1~5)를 탐색
- 폴더명(정답)과 비교하여 정확도 계산
"""

import os
from pathlib import Path
import cv2
import numpy as np
from services.run_routed_inference import RoutedInference


def calculate_iou(box1, box2):
    """두 박스 간 IoU 계산"""
    x1_min, y1_min, x1_max, y1_max = box1
    x2_min, y2_min, x2_max, y2_max = box2

    inter_x_min = max(x1_min, x2_min)
    inter_y_min = max(y1_min, y2_min)
    inter_x_max = min(x1_max, x2_max)
    inter_y_max = min(y1_max, y2_max)

    inter_area = max(0, inter_x_max - inter_x_min) * max(0, inter_y_max - inter_y_min)
    box1_area = max(0, x1_max - x1_min) * max(0, y1_max - y1_min)
    box2_area = max(0, x2_max - x2_min) * max(0, y2_max - y2_min)
    union_area = box1_area + box2_area - inter_area

    return inter_area / union_area if union_area > 0 else 0


def test_routed_performance():
    # 경로 설정
    base_dir = Path("models/Detection/Model_routing_1104")
    test_dir = Path("test/YOLO/images/test_images")
    output_dir = Path("output")
    output_dir.mkdir(exist_ok=True)

    print(f"📁 Base model dir: {base_dir.resolve()}")
    print(f"📁 Test images dir: {test_dir.resolve()}")
    print(f"📁 Output dir: {output_dir.resolve()}")

    # RoutedInference 초기화
    router = RoutedInference(str(base_dir))

    results_list = []
    correct_count = 0
    total_count = 0

    # 1~5 폴더 순회
    for folder_num in range(1, 6):
        folder_path = test_dir / str(folder_num)
        if not folder_path.exists():
            print(f"⚠️ Folder not found: {folder_path}")
            continue

        image_files = [f for f in folder_path.iterdir() if f.suffix.lower() in ['.jpg', '.jpeg', '.png', '.bmp']]
        print(f"\n📂 Processing folder {folder_num} ({len(image_files)} images)")

        for image_path in image_files:
            total_count += 1
            print(f"  ▶ {image_path.name}")

            try:
                result = router.route_infer_single_image(str(image_path))
                detections = result["detections"]

                # answer_1과 번호들(1~5) 탐색
                answer_boxes = [det["bbox"] for det in detections if det["class_name"] == "answer_1"]
                number_boxes = {i: [] for i in range(1, 6)}
                for det in detections:
                    if det["class_name"] in ["1", "2", "3", "4", "5"]:
                        number_boxes[int(det["class_name"])].append(det["bbox"])

                predicted_number = None
                max_iou = 0

                for ans_box in answer_boxes:
                    for num, boxes in number_boxes.items():
                        for box in boxes:
                            iou = calculate_iou(ans_box, box)
                            if iou > max_iou:
                                max_iou = iou
                                predicted_number = num

                is_correct = (predicted_number == folder_num)
                if is_correct:
                    correct_count += 1

                results_list.append(
                    f"{folder_num}/{image_path.name}, pred={predicted_number}, iou={max_iou:.3f}, correct={is_correct}"
                )

                print(f"    ✅ True: {folder_num}, Pred: {predicted_number}, IoU={max_iou:.3f}, Correct={is_correct}")

            except Exception as e:
                print(f"    ❌ Error processing {image_path.name}: {e}")
                continue

    # 결과 요약
    accuracy = (correct_count / total_count * 100) if total_count > 0 else 0
    print("\n" + "=" * 60)
    print(f"📊 Test Complete!")
    print(f"  Total images: {total_count}")
    print(f"  Correct predictions: {correct_count}")
    print(f"  Accuracy: {accuracy:.2f}%")
    print("=" * 60)

    # 결과 저장
    result_txt = output_dir / "routed_results.txt"
    with open(result_txt, "w", encoding="utf-8") as f:
        f.write("\n".join(results_list))
    print(f"✅ Results saved to: {result_txt.resolve()}")

    return results_list, accuracy


if __name__ == "__main__":
    test_routed_performance()
