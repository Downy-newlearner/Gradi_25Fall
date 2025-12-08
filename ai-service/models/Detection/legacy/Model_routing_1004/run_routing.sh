#!/bin/bash

echo "🚀 라우팅 추론 및 시각화 시작"
echo "🎯 모델: YOLOv8n (큰 객체) + YOLOv8s (작은 객체)"
echo "📊 전략: 모든 검출 결과 사용 (라우팅 기반)"
echo "=" * 60

# UV 환경 활성화
source /home/jdh251425/2509\ Gradi-Detection/gradi-detection/bin/activate

# 작업 디렉토리로 이동
cd "/home/jdh251425/2509 Gradi-Detection/Exp/experiment_routing_1004"

# GPU 메모리 확인
echo "📊 GPU 상태 확인:"
nvidia-smi

echo "🔥 라우팅 추론 시작..."
python run_routed_inference.py

echo "✅ 라우팅 추론 및 시각화 완료!"
