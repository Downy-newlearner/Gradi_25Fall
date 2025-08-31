"""
인식 관련 API 엔드포인트
Flask의 Blueprint와 유사한 역할
"""

from fastapi import APIRouter, File, UploadFile, HTTPException
from typing import List
import logging

from services.recognition_service import RecognitionService
from models.schemas import RecognitionRequest, RecognitionResponse

# APIRouter 생성 (Flask의 Blueprint와 동일)
router = APIRouter()

# 서비스 인스턴스 생성
recognition_service = RecognitionService()

@router.post("/analyze", response_model=RecognitionResponse)
async def analyze_image(file: UploadFile = File(...)):
    """
    이미지에서 학생 답안 인식
    
    Flask 예시:
    @app.route('/api/v1/recognition/analyze', methods=['POST'])
    def analyze_image():
        ...
    """
    try:
        # 파일 검증
        if not file.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="이미지 파일만 업로드 가능합니다.")
        
        # 이미지 처리 및 답안 인식
        result = await recognition_service.analyze_student_answer(file)
        
        return RecognitionResponse(
            success=True,
            student_answer=result.get("answer", ""),
            confidence=result.get("confidence", 0.0),
            message="답안 인식이 완료되었습니다."
        )
        
    except Exception as e:
        logging.error(f"답안 인식 중 오류 발생: {str(e)}")
        raise HTTPException(status_code=500, detail=f"답안 인식 실패: {str(e)}")

@router.post("/batch-analyze", response_model=List[RecognitionResponse])
async def batch_analyze_images(files: List[UploadFile] = File(...)):
    """
    여러 이미지 일괄 처리
    """
    try:
        results = []
        for file in files:
            if file.content_type.startswith('image/'):
                result = await recognition_service.analyze_student_answer(file)
                results.append(RecognitionResponse(
                    success=True,
                    student_answer=result.get("answer", ""),
                    confidence=result.get("confidence", 0.0),
                    message="답안 인식 완료"
                ))
        
        return results
        
    except Exception as e:
        logging.error(f"일괄 답안 인식 중 오류 발생: {str(e)}")
        raise HTTPException(status_code=500, detail=f"일괄 처리 실패: {str(e)}")

@router.get("/status")
async def get_recognition_status():
    """
    인식 서비스 상태 확인
    """
    return {
        "service": "recognition",
        "status": "active",
        "model_version": "1.0.0"
    }
