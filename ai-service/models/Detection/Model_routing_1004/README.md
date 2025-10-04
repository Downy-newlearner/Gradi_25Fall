# Routing Experiment 1004

## 개요
새로운 데이터셋 (476개 이미지)을 사용한 모델 라우팅 실험

## 모델 구성

### YOLOv8n @ 1280 (큰 객체)
- **대상 클래스**: answer_option, english_content, korean_content, section
- **GPU**: [0,1]
- **증강**: 없음
- **용도**: 큰 객체 검출

### YOLOv8s @ 2048 (작은 객체)
- **대상 클래스**: page_number, problem_number, answer_1, answer_2
- **GPU**: [2,3]
- **증강**: translate, scale, degrees(±3°), shear(±1°)
- **cls_loss_weight**: 3.0 (클래스 불균형 대응)
- **용도**: 작은 객체 검출

## 클래스 라우팅

| 클래스 | 모델 | 이유 |
|--------|------|------|
| answer_option | YOLOv8n | 큰 객체 |
| english_content | YOLOv8n | 큰 객체 |
| korean_content | YOLOv8n | 큰 객체 |
| section | YOLOv8n | 큰 객체 |
| page_number | YOLOv8s | 작은 객체 |
| problem_number | YOLOv8s | 작은 객체 |
| answer_1 | YOLOv8s | 작은 객체 |
| answer_2 | YOLOv8s | 작은 객체 |

## 데이터셋
- **원본**: english_problem_data_251004 (476개 이미지)
- **Large4**: english_large4_251004 (4개 클래스)
- **Small4**: english_small4_251004 (4개 클래스)

## 실행 순서
1. `yolov8n_imgsz_1280/START_TRAINING_UV.sh` (큰 객체 모델)
2. `yolov8s_imgsz_2048/START_TRAINING_UV.sh` (작은 객체 모델)
