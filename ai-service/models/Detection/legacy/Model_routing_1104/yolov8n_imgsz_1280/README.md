# YOLOv8n @ 1280 - 큰 객체 전용

## 목적
큰 객체들을 위한 전용 모델 (answer_option, english_content, korean_content, section)

## 설정
- **모델**: YOLOv8n
- **이미지 크기**: 1280x1280
- **GPU**: [0,1]
- **배치 크기**: 8
- **증강**: 없음 (모든 증강 비활성화)

## 데이터셋
- **경로**: `/home/jdh251425/2509 Gradi-Detection/Data/english_large4_251004/`
- **클래스**: 4개 (answer_option, english_content, korean_content, section)
- **총 이미지**: 476개 (333 train, 95 valid, 48 test)

## 실행
```bash
bash START_TRAINING_UV.sh
```
