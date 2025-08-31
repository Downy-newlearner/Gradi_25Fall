# Gradi_25Fall

Gradi, Auto grading service.

<div id="team-members">
  <h2 style="border-bottom: 2px solid #eaecef; padding-bottom: 0.3em;">팀원 소개</h2>
  <table style="width: 100%; border-collapse: collapse; text-align: center;">
    <thead>
      <tr style="background-color: #f6f8fa;">
        <th style="padding: 10px; border: 1px solid #dfe2e5;">역할</th>
        <th style="padding: 10px; border: 1px solid #dfe2e5;">이름</th>
        <th style="padding: 10px; border: 1px solid #dfe2e5;">주요 업무</th>
        <th style="padding: 10px; border: 1px solid #dfe2e5;">GitHub</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td style="padding: 10px; border: 1px solid #dfe2e5;"><strong>팀장 / AI / Frontend</strong></td>
        <td style="padding: 10px; border: 1px solid #dfe2e5;">정다훈</td>
        <td style="padding: 10px; border: 1px solid #dfe2e5; text-align: left;">프로젝트 총괄, AI 모델 구성 및 Frontend 구현</td>
        <td style="padding: 10px; border: 1px solid #dfe2e5;"><a href="https://github.com/Downy-newlearner">바로가기</a></td>
      </tr>
      <tr>
        <td style="padding: 10px; border: 1px solid #dfe2e5;"><strong>Backend 개발</strong></td>
        <td style="padding: 10px; border: 1px solid #dfe2e5;">정성원</td>
        <td style="padding: 10px; border: 1px solid #dfe2e5; text-align: left;">Spring, MySQL, MongoDB 연동, Redis, Kafka, S3 연동, AWS 구성</td>
        <td style="padding: 10px; border: 1px solid #dfe2e5;"><a href="https://github.com/woniwory">바로가기</a></td>
      </tr>
      <tr>
        <td style="padding: 10px; border: 1px solid #dfe2e5;"><strong>AI 개발</strong></td>
        <td style="padding: 10px; border: 1px solid #dfe2e5;">최예림</td>
        <td style="padding: 10px; border: 1px solid #dfe2e5; text-align: left;">FastAPI 및 AI 모델 리서치 및 개발 구현</td>
        <td style="padding: 10px; border: 1px solid #dfe2e5;"><a href="#">바로가기</a></td>
      </tr>
      <tr>
        <td style="padding: 10px; border: 1px solid #dfe2e5;"><strong>AI 개발</strong></td>
        <td style="padding: 10px; border: 1px solid #dfe2e5;">민유진</td>
        <td style="padding: 10px; border: 1px solid #dfe2e5; text-align: left;">FastAPI 및 AI 모델 리서치 및 개발 구현</td>
        <td style="padding: 10px; border: 1px solid #dfe2e5;"><a href="#">바로가기</a></td>
      </tr>
      <tr>
        <td style="padding: 10px; border: 1px solid #dfe2e5;"><strong>디자이너 / Frontend</strong></td>
        <td style="padding: 10px; border: 1px solid #dfe2e5;">최윤정</td>
        <td style="padding: 10px; border: 1px solid #dfe2e5; text-align: left;">UI 디자인 및 Frontend 구현</td>
        <td style="padding: 10px; border: 1px solid #dfe2e5;"><a href="#">바로가기</a></td>
      </tr>
    </tbody>
  </table>
</div>

## 📁 프로젝트 구조

```
Gradi_25Fall/
├── docs/                    # 📚 프로젝트 문서 및 설계서
│   ├── api/                # API 문서
│   ├── design/             # UI/UX 디자인
│   └── architecture/       # 시스템 아키텍처
├── frontend/               # 🎨 프론트엔드 애플리케이션
│   ├── src/
│   ├── public/
│   └── package.json
├── backend/                # 🔧 Spring Boot 백엔드 서비스
│   ├── src/main/java/
│   ├── src/main/resources/
│   └── build.gradle
├── ai-service/             # 🤖 FastAPI AI 서비스
│   ├── models/             # AI 모델
│   ├── api/                # FastAPI 라우터
│   └── requirements.txt
├── infrastructure/         # ☁️ 인프라 설정
│   ├── docker/             # Docker 설정
│   ├── kubernetes/         # K8s 매니페스트
│   └── terraform/          # AWS 리소스
├── database/              # 🗄️ 데이터베이스
│   ├── mysql/              # MySQL 스키마
│   ├── mongodb/            # MongoDB 컬렉션
│   └── migrations/         # 마이그레이션 스크립트
├── scripts/               # 🛠️ 유틸리티 스크립트
│   ├── deploy/             # 배포 스크립트
│   └── setup/              # 환경 설정
└── .github/               # 🔄 GitHub 설정
    ├── workflows/          # GitHub Actions
    └── ISSUE_TEMPLATE/     # 이슈 템플릿
```

## 🌿 브랜치 전략 (Git Flow 기반)

### 주요 브랜치

- **`main`** : 운영 환경 배포 브랜치 (항상 안정적인 상태 유지)
- **`develop`** : 개발 브랜치 (다음 릴리즈를 위한 기능들이 통합)

### 보조 브랜치

- **`feature/*`** : 새로운 기능 개발
  - 예: `feature/user-authentication`, `feature/ai-grading-model`
  - `develop`에서 분기하여 `develop`로 merge
- **`hotfix/*`** : 운영 환경 긴급 버그 수정
  - 예: `hotfix/login-error`
  - `main`에서 분기하여 `main`과 `develop`로 merge
- **`release/*`** : 릴리즈 준비
  - 예: `release/v1.0.0`
  - `develop`에서 분기하여 `main`과 `develop`로 merge

### 담당 영역별 브랜치 네이밍

```
frontend/
├── feature/frontend-ui-components     # 최윤정 (디자인/Frontend)
├── feature/frontend-user-dashboard    # 정다훈 (팀장/Frontend)

backend/
├── feature/backend-auth-service       # 정성원 (Backend)
├── feature/backend-grading-api        # 정성원 (Backend)

ai-service/
├── feature/ai-model-training          # 최예림 (AI)
├── feature/ai-grading-algorithm       # 민유진 (AI)
```

## 🔄 작업 플로우

### 1. 새로운 기능 개발

```bash
# develop 브랜치에서 최신 코드 pull
git checkout develop
git pull origin develop

# 새로운 feature 브랜치 생성
git checkout -b feature/기능명

# 작업 후 커밋
git add .
git commit -m "feat: 기능 설명"

# 원격 저장소에 push
git push origin feature/기능명

# GitHub에서 Pull Request 생성 (develop ← feature/기능명)
```

### 2. 코드 리뷰 규칙

- **모든 PR은 최소 2명의 리뷰 필수**
- **관련 영역 담당자의 승인 필수**
  - Frontend 변경 → 정다훈 또는 최윤정 승인
  - Backend 변경 → 정성원 승인
  - AI 변경 → 최예림 또는 민유진 승인
- **CI/CD 테스트 통과 후 merge**

### 3. 커밋 메시지 컨벤션

```
feat: 새로운 기능 추가
fix: 버그 수정
docs: 문서 수정
style: 코드 포맷팅, 세미콜론 누락 등
refactor: 코드 리팩토링
test: 테스트 추가
chore: 빌드 업무 수정, 패키지 매니저 설정 등
```

### 4. 릴리즈 프로세스

1. `develop` → `release/v1.x.x` 브랜치 생성
2. 릴리즈 테스트 및 버그 수정
3. `release/v1.x.x` → `main` merge (배포)
4. `main`에서 태그 생성
5. `main` → `develop` merge (릴리즈 변경사항 반영)

---

## 📋 개발 환경 설정

### 필수 도구

- **Node.js** 18+ (Frontend)
- **Java** 17+ (Backend)
- **Python** 3.9+ (AI Service)
- **Docker** & **Docker Compose**
- **MySQL** 8.0+
- **MongoDB** 6.0+
- **Redis** 7.0+

### 로컬 개발 환경 구축

```bash
# 1. 프로젝트 클론
git clone https://github.com/your-org/Gradi_25Fall.git
cd Gradi_25Fall

# 2. 환경별 설정
./scripts/setup/local-setup.sh

# 3. Docker 컨테이너 실행
docker-compose up -d

# 4. 각 서비스 실행
cd frontend && npm install && npm start
cd backend && ./gradlew bootRun
cd ai-service && pip install -r requirements.txt && uvicorn main:app --reload
```
