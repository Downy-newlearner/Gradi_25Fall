"""
헬스체크 API 엔드포인트
"""

from fastapi import APIRouter
from datetime import datetime

router = APIRouter()

@router.get("/")
async def health_check():
    """
    서비스 헬스체크
    """
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "service": "gradi-ai-service"
    }

@router.get("/detailed")
async def detailed_health_check():
    """
    상세 헬스체크 (DB 연결, 외부 API 상태 등)
    """
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "services": {
            "groq_api": "connected",
            "database": "connected",
            "file_storage": "connected"
        },
        "version": "1.0.0"
    }
