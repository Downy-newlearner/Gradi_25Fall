#!/usr/bin/env python3
"""
Routing Experiment 1004 - YOLOv8s @ 2048 (작은 객체 전용)
GPU 2,3 사용, 증강 + cls_loss_weight 증가
"""

import os
import sys
from pathlib import Path

def main():
    # 현재 디렉토리 설정
    current_dir = Path(__file__).parent
    os.chdir(current_dir)
    
    # 설정 파일 경로
    config_path = current_dir / "config_optimized.yaml"
    
    if not config_path.exists():
        print(f"❌ 설정 파일을 찾을 수 없습니다: {config_path}")
        sys.exit(1)
    
    print("🚀 Routing Experiment 1004 - YOLOv8s @ 2048 시작")
    print(f"📁 작업 디렉토리: {current_dir}")
    print(f"⚙️  설정 파일: {config_path}")
    print("🎯 대상: 작은 객체 (page_number, problem_number, answer_1, answer_2)")
    print("🖥️  GPU: [2,3]")
    print("🔄 증강: translate, scale, degrees(±3°), shear(±1°)")
    print("⚖️  cls_loss_weight: 3.0 (클래스 불균형 대응)")
    print("=" * 60)
    
    # YOLO 학습 실행
    from ultralytics import YOLO
    
    model = YOLO('yolov8s.pt')
    results = model.train(
        cfg=str(config_path),
        data=str(config_path.parent.parent.parent / "Data" / "english_small4_251004" / "data.yaml")
    )
    
    print("✅ 학습 완료!")
    return results

if __name__ == "__main__":
    main()
