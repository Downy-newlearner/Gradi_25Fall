# 🎯 AI 채점 서비스 (Grading Service)

Kafka 기반의 수능 영어 답안지 자동 채점 서비스입니다.

## 📋 목차

- [개요](#개요)
- [시스템 요구사항](#시스템-요구사항)
- [설치](#설치)
- [설정](#설정)
- [실행](#실행)
- [API 명세](#api-명세)
- [Kafka 메시지 형식](#kafka-메시지-형식)
- [프로젝트 구조](#프로젝트-구조)
- [트러블슈팅](#트러블슈팅)

---

## 개요

### 주요 기능

- 📷 답안지 이미지에서 학생 답안 자동 인식 (YOLO + ResNet)
- ✅ 정답 대조 및 자동 채점
- 📝 오답에 대한 LLM 기반 해설 생성
- 🔄 Kafka를 통한 비동기 메시지 처리

### 아키텍처

```
┌─────────────┐                          ┌─────────────┐
│   Backend   │  ── s3-download-url ──▶  │  AI Server  │
│   Server    │  ◀── grading-status ──   │  (FastAPI)  │
│             │  ◀── student-answer ──   │             │
│             │  ◀── answer-explanation  │             │
└─────────────┘                          └─────────────┘
        │                                       │
        ▼                                       ▼
   ┌─────────┐                           ┌──────────┐
   │   S3    │                           │  Kafka   │
   └─────────┘                           └──────────┘
```

---

## 시스템 요구사항

### 하드웨어
- GPU: NVIDIA GPU (CUDA 지원, 최소 8GB VRAM 권장)
- RAM: 16GB 이상
- Storage: 20GB 이상

### 소프트웨어
- Python 3.10+
- CUDA 12.x
- Kafka 서버

---

## 설치

### 1. 저장소 클론

```bash
git clone -b feature/recognition https://github.com/Downy-newlearner/Gradi_25Fall.git
cd Gradi_25Fall
```

### 2. 가상환경 생성

```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
# 또는
venv\Scripts\activate  # Windows
```

### 3. 패키지 설치

```bash
pip install -r requirements.txt
```

### 필수 패키지 (requirements.txt)

```txt
# Web Framework & API
fastapi>=0.100.0
uvicorn>=0.20.0
pydantic>=2.0.0

# Kafka
aiokafka>=0.8.0

# Async HTTP
aiohttp>=3.8.0

# OpenAI (LLM)
openai>=1.0.0

# Computer Vision & Deep Learning
torch>=2.0.0
torchvision>=0.15.0
ultralytics>=8.0.0
opencv-python>=4.8.0
pillow>=10.0.0

# OCR
easyocr>=1.7.0

# Data Processing
numpy>=1.24.0
pandas>=2.0.0

# Utilities
python-dotenv>=1.0.0
PyYAML>=6.0
tqdm>=4.65.0
requests>=2.28.0
```

---

## 설정

### 환경 변수 (.env)

프로젝트 루트에 `.env` 파일을 생성합니다:

```env
# Kafka 설정
KAFKA_BOOTSTRAP_SERVERS=3.34.214.133:9092

# 모델 경로
MODEL_DIR_1104=./models/Detection/legacy/Model_routing_1104
MODEL_DIR_1004=./models/Detection/legacy/Model_routing_1004
RESNET_ANSWER_1_PATH=./models/Recognition/models/answer_1_resnet.pth
RESNET_ANSWER_2_PATH=./models/Recognition/models/answer_2_resnet.pth

# 데이터 경로
ANSWER_KEY_PATH=./DB/answer.txt
CHAPTER_FILE_PATH=./DB/chapter.txt

# 기타 설정
SECTION_PADDING=50
ENABLE_LLM_EXPLANATION=true

# LLM API (Upstage Solar)
UPSTAGE_API_KEY=your_api_key_here
```

### 데이터 파일

#### DB/answer.txt (정답 파일)
```
102, 40, 3
102, 41, 4
102, 42, 2
103, 43, 1
103, 44, 5
```

#### DB/chapter.txt (챕터 매핑)
```
001, 9, 13
002, 15, 19
003, 21, 25
```

---

## 실행

### 서버 시작

```bash
python main.py
```

### 실행 확인

```bash
# 기본 상태 확인
curl http://localhost:8000/

# 상세 상태 확인
curl http://localhost:8000/health
```

### 예상 출력

```
2024-01-01 12:00:00 - INFO - ✅ 스레드 풀 초기화 완료 (LLM 해설 생성용)
2024-01-01 12:00:01 - INFO - ✅ ChapterMapper 초기화 완료: 3개 챕터 로드됨
2024-01-01 12:00:05 - INFO - ✅ HierarchicalCropPipeline 초기화 완료
2024-01-01 12:00:05 - INFO - ✅ LLM 해설 모듈 로드 완료
2024-01-01 12:00:06 - INFO - ✅ Kafka 연결 완료 (group_id=grading-service-abc12345)
```

---

## API 명세

### 헬스 체크

#### GET /
기본 상태 확인

**응답:**
```json
{
  "status": "running",
  "service": "grading-service"
}
```

#### GET /health
상세 상태 확인

**응답:**
```json
{
  "status": "healthy",
  "kafka_consumer": true,
  "kafka_producer": true,
  "pipeline": true,
  "chapter_mapper": true,
  "chapter_count": 3,
  "llm_explanation_enabled": true
}
```

---

## Kafka 메시지 형식

### 토픽 구조

| 토픽명 | 방향 | 설명 |
|--------|------|------|
| `s3-download-url` | Backend → AI | 채점 요청 |
| `grading-status` | AI → Backend | 채점 상태 |
| `student-answer` | AI → Backend | 답안 결과 |
| `answer-explanation` | AI → Backend | LLM 해설 |

---

### 1. 채점 요청 (Backend → AI)

**토픽:** `s3-download-url`

```json
{
  "downloadUrl": "https://s3.amazonaws.com/bucket/image.jpg",
  "uploadUrl": "https://s3.amazonaws.com/bucket/output/",
  "academy_user_id": 123,
  "user_id": 456,
  "class_id": 789,
  "academy_id": 101,
  "student_response_id": 1001,
  "index": 1,
  "total": 5
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| downloadUrl | string | 답안지 이미지 S3 다운로드 URL |
| uploadUrl | string | 크롭 이미지 업로드 URL |
| academy_user_id | int | 학원 사용자 ID |
| user_id | int | 사용자 ID |
| class_id | int | 반 ID |
| academy_id | int | 학원 ID |
| student_response_id | int | 학생 응답 ID |
| index | int | 현재 이미지 인덱스 |
| total | int | 전체 이미지 수 |

---

### 2. 채점 상태 (AI → Backend)

**토픽:** `grading-status`

#### 채점 시작
```json
{
  "action": "GRADING_STARTED",
  "book_id": 0,
  "academy_user_id": 123,
  "user_id": 456,
  "class_id": 789,
  "academy_id": 101,
  "student_response_id": 1001
}
```

#### 채점 완료
```json
{
  "action": "GRADING_COMPLETED",
  "book_id": 0,
  "academy_user_id": 123,
  "user_id": 456,
  "class_id": 789,
  "academy_id": 101,
  "student_response_id": 1001,
  "total_question_count": 5,
  "total_score": 3,
  "response_start_page": 102,
  "response_end_page": 102,
  "unrecognized_response_count": 0
}
```

#### 에러 발생
```json
{
  "action": "ERROR",
  "book_id": 0,
  "academy_user_id": 123,
  "user_id": 456,
  "class_id": 789,
  "academy_id": 101,
  "student_response_id": 1001,
  "total_question_count": 0,
  "total_score": 0,
  "response_start_page": 0,
  "response_end_page": 0,
  "unrecognized_response_count": 1
}
```

| action 값 | 설명 |
|-----------|------|
| GRADING_STARTED | 채점 시작 |
| GRADING_COMPLETED | 채점 완료 |
| ERROR | 에러 발생 |

---

### 3. 학생 답안 결과 (AI → Backend)

**토픽:** `student-answer`

```json
{
  "student_response_id": 1001,
  "academy_user_id": 123,
  "book_id": 0,
  "chapter_id": 1,
  "page_number": "102",
  "sections": [
    {
      "problem_number": "40",
      "answer": "3",
      "correction": true
    },
    {
      "problem_number": "41",
      "answer": "2",
      "correction": false
    },
    {
      "problem_number": "42",
      "answer": "4",
      "correction": true
    }
  ]
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| student_response_id | int | 학생 응답 ID |
| academy_user_id | int | 학원 사용자 ID |
| book_id | int | 교재 ID |
| chapter_id | int | 챕터 ID |
| page_number | string | 페이지 번호 |
| sections | array | 문제별 답안 목록 |
| sections[].problem_number | string | 문제 번호 |
| sections[].answer | string | 학생 답안 |
| sections[].correction | boolean | 정답 여부 |

---

### 4. LLM 해설 (AI → Backend)

**토픽:** `answer-explanation`

> ⚠️ 오답인 경우에만 전송됩니다.

```json
{
  "student_response_id": 1001,
  "academy_user_id": 123,
  "book_id": 0,
  "chapter_id": 1,
  "page": 102,
  "question_number": 41,
  "sub_question_number": 0,
  "explanation": "🔎 문제 41 (p.102)\n\n✅ 정답: 4\n✏️ 사용자의 선택: 2\n\n💡 상세 해설\n이 문제는 글의 흐름을 파악하는 문제입니다...\n\n🔹 해설 요약\n글의 주제를 정확히 파악하면 정답을 찾을 수 있습니다.",
  "is_correct": false,
  "score": 0
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| student_response_id | int | 학생 응답 ID |
| academy_user_id | int | 학원 사용자 ID |
| book_id | int | 교재 ID |
| chapter_id | int | 챕터 ID |
| page | int | 페이지 번호 |
| question_number | int | 문제 번호 |
| sub_question_number | int | 소문제 번호 (기본값: 0) |
| explanation | string | LLM 생성 해설 |
| is_correct | boolean | 정답 여부 |
| score | int | 점수 (정답: 1, 오답: 0) |

---

## 프로젝트 구조

```
Gradi_25Fall/
├── main.py                    # 메인 애플리케이션
├── requirements.txt           # 패키지 목록
├── .env                       # 환경 변수
│
├── api/
│   └── schemas.py             # Pydantic 스키마
│
├── services/
│   ├── hierarchical_crop.py   # 이미지 처리 파이프라인
│   ├── chapter_mapper.py      # 챕터 매핑
│   └── solution_llms.py       # LLM 해설 생성
│
├── models/
│   ├── Detection/
│   │   └── legacy/
│   │       ├── Model_routing_1104/   # YOLO 모델 (답안)
│   │       └── Model_routing_1004/   # YOLO 모델 (크롭)
│   └── Recognition/
│       ├── resnetClassifier.py       # ResNet 분류기
│       ├── ocr.py                    # OCR 모델
│       └── models/
│           ├── answer_1_resnet.pth   # ResNet 가중치
│           └── answer_2_resnet.pth
│
└── DB/
    ├── answer.txt             # 정답 파일
    ├── chapter.txt            # 챕터 매핑
    └── files/                 # 문제 JSON 파일
```

---

## 통신 흐름

```
┌──────────────────────────────────────────────────────────────┐
│                        채점 프로세스                          │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  1. [Backend] 이미지 S3 업로드                                │
│       ↓                                                      │
│  2. [Backend] s3-download-url 토픽에 메시지 발행              │
│       ↓                                                      │
│  3. [AI] 메시지 수신                                         │
│       ↓                                                      │
│  4. [AI] grading-status (GRADING_STARTED) 발행               │
│       ↓                                                      │
│  5. [AI] 이미지 다운로드 및 채점 처리                         │
│       ↓                                                      │
│  6. [AI] student-answer 토픽에 답안 결과 발행                 │
│       ↓                                                      │
│  7. [AI] (오답 시) answer-explanation 토픽에 해설 발행        │
│       ↓                                                      │
│  8. [AI] grading-status (GRADING_COMPLETED) 발행             │
│       ↓                                                      │
│  9. [Backend] 결과 수신 및 DB 저장                           │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 백엔드 연동 예시 (Java/Spring)

### Kafka Producer

```java
@Service
public class GradingRequestService {
    
    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;
    
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    public void requestGrading(GradingRequest request) throws JsonProcessingException {
        String message = objectMapper.writeValueAsString(request);
        kafkaTemplate.send("s3-download-url", message);
    }
}
```

### Kafka Consumer

```java
@Service
public class GradingResultConsumer {
    
    @KafkaListener(topics = "grading-status")
    public void handleGradingStatus(String message) {
        // 채점 상태 처리
    }
    
    @KafkaListener(topics = "student-answer")
    public void handleStudentAnswer(String message) {
        // 학생 답안 저장
    }
    
    @KafkaListener(topics = "answer-explanation")
    public void handleExplanation(String message) {
        // 해설 저장
    }
}
```

---

## 트러블슈팅

### 1. Kafka 연결 실패

```
KafkaError: Unable to connect to broker
```

**해결:**
```bash
# Kafka 서버 상태 확인
telnet 3.34.214.133 9092

# 방화벽 확인
sudo ufw status
```

### 2. 모델 로드 실패

```
FileNotFoundError: Model file not found
```

**해결:**
- 모델 파일 경로 확인
- `.env` 파일의 경로 설정 확인

### 3. GPU 메모리 부족

```
CUDA out of memory
```

**해결:**
```bash
# GPU 메모리 확인
nvidia-smi

# 다른 프로세스 종료 후 재시작
```

### 4. LLM API 오류

```
OpenAI API Error: Invalid API key
```

**해결:**
- `.env` 파일의 `UPSTAGE_API_KEY` 확인
- API 키 유효성 확인

---

## 라이선스

MIT License

---

## 문의

문제가 있으시면 이슈를 등록해주세요.
