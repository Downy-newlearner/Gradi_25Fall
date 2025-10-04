# YOLOv8s @ 2048 - 작은 객체 전용

## 목적
작은 객체들을 위한 전용 모델 (page_number, problem_number, answer_1, answer_2)

## 설정
- **모델**: YOLOv8s
- **이미지 크기**: 2048x2048
- **GPU**: [2,3]
- **배치 크기**: 4
- **증강**: translate(0.02), scale(0.05), degrees(±3°), shear(±1°)

## Loss 설정
- **cls_loss_weight**: 3.0 (클래스 불균형 대응)
- **box_loss_weight**: 7.5
- **dfl_loss_weight**: 1.5

## 데이터셋
- **경로**: `/home/jdh251425/2509 Gradi-Detection/Data/english_small4_251004/`
- **클래스**: 4개 (page_number, problem_number, answer_1, answer_2)
- **클래스 분포**: problem_number(1188), answer_1(845), answer_2(861), page_number(506)
- **총 이미지**: 476개 (333 train, 95 valid, 48 test)

## 실행
```bash
bash START_TRAINING_UV.sh
```
