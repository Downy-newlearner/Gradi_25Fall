"""
FastAPI 메인 애플리케이션
Flask의 app.py와 동일한 역할
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api.v1 import recognition, grading, health

# FastAPI 앱 생성 (Flask의 app = Flask(__name__)과 동일)
app = FastAPI(
    title="Gradi AI Service",
    description="자동 채점 시스템을 위한 AI 서비스",
    version="1.0.0"
)

# CORS 설정 (프론트엔드와 통신을 위해)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],  # React 개발 서버
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API 라우터 등록 (Flask의 Blueprint 등록과 유사)
app.include_router(health.router, prefix="/api/v1/health", tags=["health"])
app.include_router(recognition.router, prefix="/api/v1/recognition", tags=["recognition"])
app.include_router(grading.router, prefix="/api/v1/grading", tags=["grading"])

@app.get("/")
async def root():
    """
    루트 엔드포인트 - 서비스 상태 확인
    """
    return {
        "message": "Gradi AI Service is running!",
        "version": "1.0.0",
        "docs": "/docs"  # Swagger UI 접근 경로
    }

if __name__ == "__main__":
    import uvicorn
    # Flask의 app.run()과 동일
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
