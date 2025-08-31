"""
Pydantic 모델 정의
Flask-Marshmallow와 유사한 역할 (데이터 검증 및 직렬화)
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class RecognitionRequest(BaseModel):
    """
    답안 인식 요청 모델
    """
    image_data: str = Field(..., description="Base64 인코딩된 이미지 데이터")
    question_id: Optional[str] = Field(None, description="문제 ID")
    
class RecognitionResponse(BaseModel):
    """
    답안 인식 응답 모델
    """
    success: bool = Field(..., description="인식 성공 여부")
    student_answer: str = Field("", description="인식된 학생 답안")
    confidence: float = Field(0.0, description="인식 신뢰도 (0-1)")
    message: str = Field("", description="처리 결과 메시지")
    processing_time: Optional[float] = Field(None, description="처리 시간(초)")

class GradingRequest(BaseModel):
    """
    채점 요청 모델
    """
    student_answer: str = Field(..., description="학생 답안")
    correct_answer: str = Field(..., description="정답")
    question_type: str = Field("short_answer", description="문제 유형")
    question_id: Optional[str] = Field(None, description="문제 ID")
    max_score: int = Field(100, description="최대 점수")

class GradingResponse(BaseModel):
    """
    채점 응답 모델
    """
    success: bool = Field(..., description="채점 성공 여부")
    score: int = Field(..., description="획득 점수")
    max_score: int = Field(..., description="최대 점수")
    is_correct: bool = Field(..., description="정답 여부")
    feedback: str = Field("", description="피드백 메시지")
    graded_at: datetime = Field(default_factory=datetime.now, description="채점 시간")

class BatchProcessingRequest(BaseModel):
    """
    일괄 처리 요청 모델
    """
    items: List[dict] = Field(..., description="처리할 항목들")
    batch_id: Optional[str] = Field(None, description="배치 ID")

class BatchProcessingResponse(BaseModel):
    """
    일괄 처리 응답 모델
    """
    batch_id: str = Field(..., description="배치 ID")
    total_count: int = Field(..., description="총 항목 수")
    success_count: int = Field(..., description="성공한 항목 수")
    failure_count: int = Field(..., description="실패한 항목 수")
    results: List[dict] = Field(..., description="처리 결과들")
    
class ErrorResponse(BaseModel):
    """
    에러 응답 모델
    """
    error: bool = Field(True, description="에러 발생 여부")
    message: str = Field(..., description="에러 메시지")
    error_code: Optional[str] = Field(None, description="에러 코드")
    timestamp: datetime = Field(default_factory=datetime.now, description="에러 발생 시간")
