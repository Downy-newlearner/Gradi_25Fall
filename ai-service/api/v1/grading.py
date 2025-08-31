"""
채점 관련 API 엔드포인트
"""

from fastapi import APIRouter, HTTPException
from typing import List
import logging

from services.grading_service import GradingService
from models.schemas import GradingRequest, GradingResponse

router = APIRouter()

# 서비스 인스턴스
grading_service = GradingService()

@router.post("/evaluate", response_model=GradingResponse)
async def evaluate_answer(request: GradingRequest):
    """
    학생 답안 채점
    """
    try:
        result = await grading_service.grade_answer(
            student_answer=request.student_answer,
            correct_answer=request.correct_answer,
            question_type=request.question_type
        )
        
        return GradingResponse(
            success=True,
            score=result.get("score", 0),
            max_score=result.get("max_score", 100),
            feedback=result.get("feedback", ""),
            is_correct=result.get("is_correct", False)
        )
        
    except Exception as e:
        logging.error(f"채점 중 오류 발생: {str(e)}")
        raise HTTPException(status_code=500, detail=f"채점 실패: {str(e)}")

@router.post("/batch-evaluate", response_model=List[GradingResponse])
async def batch_evaluate_answers(requests: List[GradingRequest]):
    """
    여러 답안 일괄 채점
    """
    try:
        results = []
        for request in requests:
            result = await grading_service.grade_answer(
                student_answer=request.student_answer,
                correct_answer=request.correct_answer,
                question_type=request.question_type
            )
            results.append(GradingResponse(
                success=True,
                score=result.get("score", 0),
                max_score=result.get("max_score", 100),
                feedback=result.get("feedback", ""),
                is_correct=result.get("is_correct", False)
            ))
        
        return results
        
    except Exception as e:
        logging.error(f"일괄 채점 중 오류 발생: {str(e)}")
        raise HTTPException(status_code=500, detail=f"일괄 채점 실패: {str(e)}")
