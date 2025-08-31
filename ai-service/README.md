# 🤖 Gradi AI Service

Gradi 자동 채점 시스템의 AI 서비스 모듈입니다. FastAPI를 기반으로 구축되었으며, 학생 답안 인식 및 자동 채점 기능을 제공합니다.

## 📁 프로젝트 구조

```
ai-service/
├── app.py                          # 🚀 FastAPI 메인 애플리케이션
├── requirements.txt                # 📦 Python 의존성 패키지
├── README.md                       # 📖 프로젝트 문서
├── .env.example                    # 🔑 환경변수 예시 파일
│
├── config/                         # ⚙️ 설정 관리
│   ├── __init__.py
│   └── settings.py                 # 애플리케이션 환경설정
│
├── api/                           # 🌐 API 라우터 (FastAPI Router)
│   ├── __init__.py
│   └── v1/                        # API 버전 1
│       ├── __init__.py
│       ├── recognition.py         # 답안 인식 API
│       ├── grading.py            # 자동 채점 API
│       └── health.py             # 헬스체크 API
│
├── services/                      # 🔧 비즈니스 로직 레이어
│   ├── __init__.py
│   ├── recognition_service.py     # 답안 인식 서비스
│   └── grading_service.py         # 자동 채점 서비스
│
├── models/                        # 📊 데이터 모델 & ML 모델
│   ├── __init__.py
│   ├── schemas.py                 # Pydantic 데이터 모델
│   └── recognition/               # 답안 인식 모델
│       ├── __init__.py
│       ├── llm_test.py           # Groq LLM 기반 답안 인식
│       ├── annotation.txt         # 인식 결과 주석
│       ├── annotation_wrong_answer.txt  # 오답 인식 주석
│       └── exp_images/           # 실험용 이미지 폴더
│           └── (테스트 이미지들)
│
├── utils/                         # 🛠️ 유틸리티 함수
│   ├── __init__.py
│   └── image_processor.py         # 이미지 처리 유틸리티
│
└── tests/                         # 🧪 테스트 코드
    ├── __init__.py
    ├── test_recognition.py
    └── test_grading.py
```

## 🔧 주요 구성 요소

### 1. **app.py** - 메인 애플리케이션
- FastAPI 애플리케이션 초기화
- CORS 설정 및 미들웨어 구성
- API 라우터 등록
- 서버 실행 설정

### 2. **api/v1/** - API 엔드포인트
- **recognition.py**: 이미지에서 학생 답안 인식 API
- **grading.py**: 인식된 답안 자동 채점 API  
- **health.py**: 서비스 상태 확인 API

### 3. **services/** - 비즈니스 로직
- **recognition_service.py**: Groq LLM을 활용한 답안 인식 로직
- **grading_service.py**: 답안 채점 알고리즘 및 피드백 생성

### 4. **models/** - 데이터 & ML 모델
- **schemas.py**: API 요청/응답 데이터 모델 (Pydantic)
- **recognition/**: 답안 인식 관련 모델 및 실험 코드

### 5. **utils/** - 유틸리티
- **image_processor.py**: 이미지 전처리, 형식 변환, 크기 조정

### 6. **config/** - 설정 관리
- **settings.py**: 환경변수, API 키, 데이터베이스 설정

## 🚀 설치 및 실행

### 1. 의존성 설치
```bash
cd ai-service

# 가상환경 생성 (권장)
python -m venv venv
source venv/bin/activate  # macOS/Linux
# venv\Scripts\activate   # Windows

# 패키지 설치
pip install -r requirements.txt
```

### 2. 환경변수 설정
```bash
# .env 파일 생성
cp .env.example .env

# .env 파일에 필요한 API 키 설정
GROQ_API_KEY=your_groq_api_key_here
MONGODB_URL=mongodb://localhost:27017
REDIS_URL=redis://localhost:6379
```

### 3. 서버 실행
```bash
# 개발 모드 (자동 재시작)
python app.py

# 또는 uvicorn 직접 실행
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

### 4. API 문서 확인
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## 📡 API 엔드포인트

### 🏥 헬스체크
```
GET  /api/v1/health/          # 기본 헬스체크
GET  /api/v1/health/detailed  # 상세 헬스체크
```

### 🔍 답안 인식
```
POST /api/v1/recognition/analyze        # 단일 이미지 답안 인식
POST /api/v1/recognition/batch-analyze  # 다중 이미지 일괄 인식
GET  /api/v1/recognition/status         # 인식 서비스 상태
```

### 📝 자동 채점
```
POST /api/v1/grading/evaluate           # 단일 답안 채점
POST /api/v1/grading/batch-evaluate     # 다중 답안 일괄 채점
```

## 🎯 주요 기능

### 1. **학생 답안 인식**
- Groq LLM API를 활용한 수학 문제 답안 텍스트 추출
- 다양한 답안 형식 지원 (단답형, 객관식, 복수답, 꼬리문제)
- 이미지 전처리 및 최적화
- 인식 신뢰도 및 처리 시간 제공

### 2. **자동 채점**
- 문제 유형별 채점 알고리즘
- 정답 비교 및 부분 점수 처리
- 개인화된 피드백 생성
- 채점 결과 상세 분석

### 3. **일괄 처리**
- 다중 파일 업로드 및 처리
- 배치 작업 상태 추적
- 처리 결과 통계 제공

## 🛠️ 개발 가이드

### 새로운 API 추가
1. `api/v1/` 디렉토리에 라우터 파일 생성
2. `services/` 디렉토리에 비즈니스 로직 구현
3. `models/schemas.py`에 데이터 모델 정의
4. `app.py`에 라우터 등록

### 새로운 인식 모델 추가
1. `models/` 디렉토리에 모델별 폴더 생성
2. 모델 로직 및 설정 파일 구현
3. `services/recognition_service.py`에 통합

### 테스트 실행
```bash
# 전체 테스트
pytest

# 특정 테스트 파일
pytest tests/test_recognition.py

# 커버리지 포함
pytest --cov=. tests/
```

## 📋 의존성

### 핵심 라이브러리
- **FastAPI**: 웹 프레임워크
- **Groq**: LLM API 클라이언트
- **Pydantic**: 데이터 검증
- **Pillow**: 이미지 처리
- **python-dotenv**: 환경변수 관리

### ML/AI 라이브러리
- **torch**: PyTorch
- **transformers**: Hugging Face 트랜스포머
- **scikit-learn**: 머신러닝
- **numpy, pandas**: 데이터 처리

### 데이터베이스 & 저장소
- **pymongo**: MongoDB 연결
- **redis**: Redis 캐시
- **boto3**: AWS S3 연동

## 🔒 보안 고려사항

- API 키는 환경변수로 관리
- 파일 업로드 크기 제한 (10MB)
- 지원하는 이미지 형식만 허용
- CORS 정책 적용
- 입력 데이터 검증 및 sanitization

## 📞 문의 및 지원

- **팀장**: 정다훈 (@정다훈)
- **AI 개발**: 최예림, 민유진
- **이슈 등록**: GitHub Issues
- **문서**: `/docs` 엔드포인트
