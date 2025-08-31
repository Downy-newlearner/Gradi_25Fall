"""
애플리케이션 설정
Flask의 config.py와 동일한 역할
"""

import os
from pydantic import BaseSettings
from typing import List

class Settings(BaseSettings):
    """
    환경 설정 클래스
    Flask의 Config 클래스와 동일한 역할
    """
    
    # 기본 설정
    APP_NAME: str = "Gradi AI Service"
    VERSION: str = "1.0.0"
    DEBUG: bool = False
    
    # 서버 설정
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # CORS 설정
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:3000",  # React 개발 서버
        "http://localhost:8080",  # Spring Boot 개발 서버
        "https://gradi.com"       # 프로덕션 도메인
    ]
    
    # API 키 설정
    GROQ_API_KEY: str = os.getenv("GROQ_API_KEY", "")
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    
    # 데이터베이스 설정
    MONGODB_URL: str = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379")
    
    # 파일 업로드 설정
    MAX_FILE_SIZE: int = 10 * 1024 * 1024  # 10MB
    ALLOWED_EXTENSIONS: List[str] = [".jpg", ".jpeg", ".png", ".webp"]
    UPLOAD_FOLDER: str = "uploads"
    
    # AWS S3 설정
    AWS_ACCESS_KEY_ID: str = os.getenv("AWS_ACCESS_KEY_ID", "")
    AWS_SECRET_ACCESS_KEY: str = os.getenv("AWS_SECRET_ACCESS_KEY", "")
    AWS_REGION: str = os.getenv("AWS_REGION", "ap-northeast-2")
    S3_BUCKET_NAME: str = os.getenv("S3_BUCKET_NAME", "gradi-files")
    
    # 로깅 설정
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    LOG_FILE: str = "logs/app.log"
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

# 전역 설정 인스턴스
settings = Settings()

# Flask 스타일로도 사용 가능
class Config:
    """
    Flask 스타일 설정 클래스 (호환성을 위해)
    """
    GROQ_API_KEY = settings.GROQ_API_KEY
    MONGODB_URL = settings.MONGODB_URL
    DEBUG = settings.DEBUG
    MAX_FILE_SIZE = settings.MAX_FILE_SIZE
