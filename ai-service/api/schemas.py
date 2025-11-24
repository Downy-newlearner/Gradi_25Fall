# schemas.py
from typing import List
from pydantic import BaseModel

class DownloadUrlRequest(BaseModel):
    """ 백엔드에서 전송하는 S3 다운로드 URL 요청 메시지 """
    downloadUrl: str
    uploadUrl: str
    academy_user_id: int
    user_id: int
    class_id: int
    academy_id: int
    student_response_id: int
    index: int
    total: int

class GradingStartMessage(BaseModel):
    """ 채점 시작 메시지 """
    action: str  # GRADING_STARTED, ERROR
    book_id: int
    academy_user_id: int
    user_id: int
    class_id: int 
    academy_id: int
    student_response_id: int

class GradingEndMessage(BaseModel):
    """ 채점 종료 메시지 """
    action: str  # GRADING_COMPLETED, ERROR
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
    problem_number: str
    answer: str
    correction: bool

class StudentAnswerMessage(BaseModel):
    """학생 답안 메시지"""
    student_response_id: int
    academy_user_id: int
    book_id: int
    chapter_id: int
    page_number: str
    sections: List[SectionAnswer]

class AnswerExplanationRequest(BaseModel):
    """ 답안 해설 요청 메시지 """
    student_response_id: int
    academy_user_id: int

class AnswerExplanationMessage(BaseModel):
    """ 답안 해설 메시지 """
    student_response_id: int
    academy_user_id: int
    book_id: int
    chapter_id: int
    page: int
    question_number: int
    sub_question_number: int
    explanation: str
    is_correct: bool
    score: int = 1