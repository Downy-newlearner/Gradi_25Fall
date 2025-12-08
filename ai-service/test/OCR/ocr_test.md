# 📁 OCR 테스트 구조
```
project/                          # OCR 모델별 페이지/문제 번호 인식 성능 비교 프로젝트
├── images/                       # OCR 입력 이미지 및 정답(label) 데이터 폴더
│   ├── page_number/              # 페이지 번호 인식용 이미지
│   ├── problem_number/           # 문제 번호 인식용 이미지
│   ├── page_number.txt           # 각 페이지 번호 이미지의 정답(label) 정보
│   └── problem_number.txt        # 각 문제 번호 이미지의 정답(label) 정보
│
├── ocr_model/                    # 다양한 OCR 엔진별 모델 구현 폴더
│   ├── __init__.py               # 패키지 초기화 파일 (모델 클래스 import용)
│   ├── easyocr_model.py          # EasyOCR 기반 인식 모델 구현 (PyTorch 기반 다국어 지원)
│   ├── tesseract_model.py        # Tesseract OCR 기반 인식 모델 구현 (pytesseract 사용)
│   ├── paddleocr_model.py        # PaddleOCR 기반 인식 모델 구현 (딥러닝 기반 OCR)
│   └── cnocr_model.py            # CnOCR 기반 인식 모델 구현 (중국어/한글 OCR에 강점)
│
├── test_result/                        # OCR 실행 결과 및 성능 평가 결과 저장 폴더
│   ├── easyocr_page_number.txt         # EasyOCR로 추출한 페이지 번호 인식 결과
│   ├── easyocr_problem_number.txt      # EasyOCR로 추출한 문제 번호 인식 결과
│   ├── tesseract_page_number.txt       # Tesseract로 추출한 페이지 번호 인식 결과
│   ├── tesseract_problem_number.txt    # Tesseract로 추출한 문제 번호 인식 결과
│   ├── paddleocr_page_number.txt       # PaddleOCR로 추출한 페이지 번호 인식 결과
│   ├── paddleocr_problem_number.txt    # PaddleOCR로 추출한 문제 번호 인식 결과
│   ├── cnocr_page_number.txt           # CnOCR로 추출한 페이지 번호 인식 결과
│   ├── cnocr_problem_number.txt        # CnOCR로 추출한 문제 번호 인식 결과
│   └── ocr_accuracy_results.csv        # 각 모델별 인식 정확도 비교 표
│
└── ocr_test.py                   # 메인 실행 스크립트: 
                                  # - 모든 OCR 모델 불러오기
                                  # - 각 이미지셋(page/problem)별 인식 수행
                                  # - 정답과 비교하여 정확도 계산 후 결과 저장

```

</br>

### 🔧 필요한 라이브러리 설치
Tesseract 추가 설치: Tesseract OCR은 별도 설치가 필요합니다.
- Windows: https://github.com/UB-Mannheim/tesseract/wiki
- Mac: brew install tesseract
- Linux: sudo apt-get install tesseract-ocr

```python
conda create -n ocr python=3.11 -y
conda activate ocr

pip install "numpy<2"
pip install pytesseract easyocr paddleocr paddlepaddle cnocr onnxruntime
```
- numpy 버전 충돌 때문에 별도의 가상 환경을 생성하는 것을 추천합니다.

</br>

### 📝 주요 기능

- 각 모델별 OCR 클래스: 이미지에서 숫자를 추출하는 extract_number() 메서드 구현
- 자동 이미지 처리: 각 폴더의 모든 이미지를 순차적으로 처리
- 결과 저장: {모델명}_page_number.txt 및 {모델명}_problem_number.txt 형식으로 저장
- CSV 출력: 모든 모델의 정확도를 CSV 파일로 저장

**측정 내용**
- page_total_time: Page number 전체 처리 시간 (초)
- page_avg_time: Page number 이미지당 평균 시간 (초)
- problem_total_time: Problem number 전체 처리 시간 (초)
- problem_avg_time: Problem number 이미지당 평균 시간 (초)
- overall_total_time: 전체 이미지 처리 총 시간 (초)
- overall_avg_time: 전체 이미지 평균 처리 시간 (초)

</br>

### 🚀 실행 방법
```
python ocr_test.py
```
실행 결과로 다음 파일들이 생성됩니다:
- `easyocr_page_number.txt`, `easyocr_problem_number.txt`
- `tesseract_page_number.txt`, `tesseract_problem_number.txt`
- `paddleocr_page_number.txt`, `paddleocr_problem_number.txt`
- `cnocr_page_number.txt`, `cnocr_problem_number.txt`
- `ocr_accuracy_results.csv` (최종 정확도 결과)

</br>

### 📊 출력 결과
```
============================================================
FINAL RESULTS
============================================================

Model           Page Num %      Problem Num %   Average %      
------------------------------------------------------------
easyocr         100.00          100.00          100.00         
tesseract       94.64           90.19           92.42          
paddleocr       0.00            0.00            0.00           
cnocr           3.57            0.00            1.79    
```