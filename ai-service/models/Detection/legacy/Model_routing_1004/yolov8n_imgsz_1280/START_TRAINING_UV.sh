#!/bin/bash

echo "🚀 Routing Experiment 1004 - YOLOv8n @ 1280 시작"
echo "🎯 대상: 큰 객체 (answer_option, english_content, korean_content, section)"
echo "🖥️  GPU: [0,1]"
echo "🔄 증강: 없음"
echo "📊 데이터: english_large4_251004"
echo "=" * 60

# UV 환경 활성화
source /home/jdh251425/2509\ Gradi-Detection/gradi-detection/bin/activate

# 작업 디렉토리로 이동
cd "/home/jdh251425/2509 Gradi-Detection/experiment_routing_1004/yolov8n_imgsz_1280"

# GPU 메모리 확인
echo "📊 GPU 상태 확인:"
nvidia-smi

echo "🔥 학습 시작..."
python run_optimized_training.py

echo "✅ 학습 완료!"
