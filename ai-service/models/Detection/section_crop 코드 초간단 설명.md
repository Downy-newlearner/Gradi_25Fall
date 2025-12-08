# Section Crop 사용 설명서

## 사용 방법

```bash
python section_crop.py
```

## 입력 데이터

- **위치**: `ai-service/models/recognition/exp_images/` 폴더
- **파일 형식**: `.jpg`, `.jpeg`, `.png`, `.bmp` 이미지 파일

## 사용 모델

- **모델 파일**: `yolov8l_best_0904.pt` (같은 폴더에 위치)
- **모델 타입**: YOLOv8 객체 검출 모델

## 출력 결과

1. **예측 시각화**: `ai-service/models/Detection/predictions_visualization/`

   - 검출 결과가 표시된 이미지들

2. **크롭된 Section 이미지**: `ai-service/models/Detection/sections/`
   - 검출된 각 section이 개별 이미지로 크롭되어 저장
   - 파일명 형식: `원본파일명_section_번호_conf신뢰도.jpg`

## 실행 전 확인사항

- `exp_images/` 폴더에 처리할 이미지가 있는지 확인
- `yolov8l_best_0904.pt` 모델 파일이 같은 폴더에 있는지 확인
