#!/bin/bash

# Gradi 프로젝트 로컬 개발 환경 설정 스크립트

echo "🚀 Gradi 프로젝트 로컬 환경 설정을 시작합니다..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 함수: 성공 메시지
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# 함수: 경고 메시지
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 함수: 에러 메시지
error() {
    echo -e "${RED}❌ $1${NC}"
}

# Node.js 및 npm 설치 확인
echo "📦 Node.js 설치 확인 중..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    success "Node.js $NODE_VERSION 설치됨"
else
    error "Node.js가 설치되지 않았습니다. https://nodejs.org에서 Node.js 18+ 설치하세요."
    exit 1
fi

# Java 설치 확인
echo "☕ Java 설치 확인 중..."
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    success "Java 설치됨: $JAVA_VERSION"
else
    error "Java가 설치되지 않았습니다. OpenJDK 17+ 설치하세요."
    exit 1
fi

# Python 설치 확인
echo "🐍 Python 설치 확인 중..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    success "$PYTHON_VERSION 설치됨"
else
    error "Python3가 설치되지 않았습니다. Python 3.9+ 설치하세요."
    exit 1
fi

# Docker 설치 확인
echo "🐳 Docker 설치 확인 중..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    success "$DOCKER_VERSION 설치됨"
else
    error "Docker가 설치되지 않았습니다. https://docker.com에서 Docker 설치하세요."
    exit 1
fi

# 프로젝트 루트로 이동
cd "$(dirname "$0")/../.."

# Frontend 의존성 설치
echo "🎨 Frontend 의존성 설치 중..."
cd frontend
if [ -f package.json ]; then
    npm install
    success "Frontend 의존성 설치 완료"
else
    warning "package.json이 없습니다. 수동으로 설정하세요."
fi
cd ..

# AI Service 가상환경 생성 및 의존성 설치
echo "🤖 AI Service 환경 설정 중..."
cd ai-service
if [ -f requirements.txt ]; then
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    success "AI Service 환경 설정 완료"
    deactivate
else
    warning "requirements.txt가 없습니다. 수동으로 설정하세요."
fi
cd ..

# Backend Gradle 권한 설정
echo "🔧 Backend 설정 중..."
cd backend
if [ -f gradlew ]; then
    chmod +x gradlew
    success "Gradle 권한 설정 완료"
fi
cd ..

# 환경 변수 파일 생성
echo "📝 환경 설정 파일 생성 중..."
if [ ! -f .env ]; then
    cat > .env << EOF
# Database
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DATABASE=gradi
MYSQL_USER=gradi_user
MYSQL_PASSWORD=gradi123

MONGODB_HOST=localhost
MONGODB_PORT=27017
MONGODB_DATABASE=gradi
MONGODB_USER=gradi_admin
MONGODB_PASSWORD=gradi123

REDIS_HOST=localhost
REDIS_PORT=6379

# Kafka
KAFKA_BOOTSTRAP_SERVERS=localhost:9092

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production

# AWS (개발환경에서는 로컬 MinIO 사용 권장)
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=ap-northeast-2
AWS_S3_BUCKET=gradi-files

# AI Service
AI_SERVICE_URL=http://localhost:8000
MODEL_PATH=./models/
EOF
    success "환경 설정 파일(.env) 생성 완료"
else
    warning ".env 파일이 이미 존재합니다."
fi

echo ""
echo "🎉 로컬 환경 설정이 완료되었습니다!"
echo ""
echo "다음 단계:"
echo "1. Docker 컨테이너 실행: docker-compose up -d"
echo "2. Frontend 실행: cd frontend && npm run dev"
echo "3. Backend 실행: cd backend && ./gradlew bootRun"
echo "4. AI Service 실행: cd ai-service && source venv/bin/activate && uvicorn main:app --reload"
echo ""
echo "📊 접속 URL:"
echo "- Frontend: http://localhost:3000"
echo "- Backend API: http://localhost:8080"
echo "- AI Service: http://localhost:8000"
echo "- MySQL: localhost:3306"
echo "- MongoDB: localhost:27017"
echo "- Redis: localhost:6379"
