# experiment_routing_0930

## 목적
- 큰 객체: YOLOv8n @ 1280
- 작은 객체: YOLOv8s @ 2048
- 경량 증강(translate=0.02, scale=0.05) 적용

## 학습 시작
```bash
# 큰 객체 모델
cd /home/jdh251425/2509\ Gradi-Detection/experiment_routing_0930/yolov8n_imgsz_1280
bash START_TRAINING_UV.sh

# 작은 객체 모델
cd /home/jdh251425/2509\ Gradi-Detection/experiment_routing_0930/yolov8s_imgsz_2048
bash START_TRAINING_UV.sh
```

## 라우팅 추론
```bash
cd /home/jdh251425/2509\ Gradi-Detection/experiment_routing_0930
uv run python run_routed_inference.py /path/to/image.jpg
```

## 클래스 라우팅
- 작은 객체: page_number, problem_number, answer_1, answer_2 → YOLOv8s@2048 (conf=0.22)
- 큰 객체: korean_content, english_content, section, answer_option → YOLOv8n@1280 (conf=0.12)
