# api/schemas.py
"""
Kafka 메시지 스키마 정의
"""
from typing import List, Optional
from pydantic import BaseModel


class DownloadUrlRequest(BaseModel):
    """백엔드에서 전송하는 S3 다운로드 URL 요청 메시지"""
    total: int
    academy_id: int
    file_name: str
    class_id: int
    download_url: str
    academy_user_id: int
    index: int
    student_response_id: int
    # 선택적 필드 (백엔드에서 보내지 않을 수 있음)
    upload_url: Optional[str] = None
    user_id: Optional[int] = None


class GradingStartMessage(BaseModel):
    """채점 시작 메시지"""
    action: str  # GRADING_STARTED, ERROR
    book_id: int
    academy_user_id: int
    user_id: int
    class_id: int
    academy_id: int
    student_response_id: int


class GradingEndMessage(BaseModel):
    """채점 종료 메시지"""
    action: str  # GRADING_ENDED, ERROR
    book_id: int
    academy_user_id: int
    user_id: int
    class_id: int
    academy_id: int
    student_response_id: int
    total_question_count: int
    total_score: int
    response_start_page: int
    response_end_page: int
    unrecognized_response_count: int


class SectionAnswer(BaseModel):
    """개별 문제 답안"""
    question_number: int
    sub_question_number: int
    answer: str
    is_correct: bool


class StudentAnswerMessage(BaseModel):
    """학생 답안 메시지"""
    student_response_id: int
    academy_user_id: int
    book_id: int
    chapter_id: int
    page: int
    score: int
    sections: List[SectionAnswer]


class AnswerExplanationMessage(BaseModel):
    """
    답안 해설 메시지
    
    오답 시 자동으로 생성되어 answer-explanation 토픽으로 전송됨
    """
    student_response_id: int
    academy_user_id: int
    user_id: int
    book_id: int
    chapter_id: int
    page: int
    question_number: int
    sub_question_number: int
    explanation: str


# ============================================================
# 해설 API 스키마
# ============================================================

class ExplanationRequest(BaseModel):
    """해설 생성 요청 스키마 (백엔드 → AI 서버)"""
    student_response_id: int
    academy_user_id: int
    user_id: int
    page_number: int
    question_number: int
    answer: Optional[int] = None  # 사용자 답안 (선택적)


class ExplanationResponseItem(BaseModel):
    """개별 문제 해설 응답"""
    book_id: int
    chapter_id: int
    page: int
    question_number: int
    sub_question_number: int
    explanation: str


class ExplanationResponse(BaseModel):
    """해설 생성 응답 스키마 (AI 서버 → 백엔드) - 단일 문제"""
    success: bool
    student_response_id: int
    academy_user_id: int
    user_id: int
    explanation: Optional[ExplanationResponseItem] = None  # 단일 해설
    kafka_sent: bool = False
    error: Optional[str] = None


class BatchExplanationRequest(BaseModel):
    """배치 해설 생성 요청 스키마"""
    requests: List[ExplanationRequest]


class BatchExplanationResponse(BaseModel):
    """배치 해설 생성 응답 스키마"""
    total: int
    success_count: int
    failed_count: int
    results: List[ExplanationResponse]