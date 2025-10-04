#!/bin/bash

echo "🚀 Routing Experiment 1004 - YOLOv8s @ 2048 시작"
echo "🎯 대상: 작은 객체 (page_number, problem_number, answer_1, answer_2)"
echo "🖥️  GPU: [2,3]"
echo "🔄 증강: translate, scale, degrees(±3°), shear(±1°)"
echo "⚖️  cls_loss_weight: 3.0 (클래스 불균형 대응)"
echo "📊 데이터: english_small4_251004"
echo "=" * 60

# UV 환경 활성화
source /home/jdh251425/2509\ Gradi-Detection/gradi-detection/bin/activate

# 작업 디렉토리로 이동
cd "/home/jdh251425/2509 Gradi-Detection/experiment_routing_1004/yolov8s_imgsz_2048"

# GPU 메모리 확인
echo "📊 GPU 상태 확인:"
nvidia-smi

echo "🔥 학습 시작..."
python run_optimized_training.py

echo "✅ 학습 완료!"
