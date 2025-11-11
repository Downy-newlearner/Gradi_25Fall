# 라우팅 추론 및 평가 결과

## 실행 방법

> !! main 함수에 있는 경로 설정을 확인 후 실행하세요 !!

```bash
python infer_and_evaluate.py
```

## 실행 순서

1. **큰 객체 탐지** (best_big_objects.pt)

   - 클래스: answer_option, english_content, korean_content, section
   - 이미지 크기: 1280px
   - 신뢰도 임계값: 0.5 (변경 자유)

2. **작은 객체 탐지** (best_small_objects.pt)

   - 클래스: page_number, problem_number, answer_1, answer_2, 1, 2, 3, 4, 5
   - 이미지 크기: 2048px
   - 신뢰도 임계값: 0.5 (변경 자유)

3. **후처리** (post-processing.py)
   - section bbox 교정
   - 원본 section은 original_section으로 변경

## 출력 디렉토리

- `results/inference_results/`: 추론 결과 (JSON + 시각화 이미지)
- `results/post_processed_results/`: 후처리 결과 (JSON + 시각화 이미지)
- `results/evaluation/`: 추론 결과 평가
- `results/evaluation_post_processed/`: 후처리 결과 평가

## 평가 지표

- 총 이미지 수
- 총 검출 수
- 이미지당 평균 검출 수
- 평균 신뢰도
- 클래스별 검출 수
