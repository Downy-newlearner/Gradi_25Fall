"""
채점 서비스
"""

from typing import Dict, Any, List
import logging

class GradingService:
    """
    답안 채점 관련 비즈니스 로직
    """
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
    
    async def grade_answer(
        self, 
        student_answer: str, 
        correct_answer: str, 
        question_type: str = "short_answer"
    ) -> Dict[str, Any]:
        """
        학생 답안을 채점
        
        Args:
            student_answer: 학생이 작성한 답안
            correct_answer: 정답
            question_type: 문제 유형 (short_answer, multiple_choice, essay 등)
            
        Returns:
            채점 결과
        """
        try:
            if question_type == "short_answer":
                return await self._grade_short_answer(student_answer, correct_answer)
            elif question_type == "multiple_choice":
                return await self._grade_multiple_choice(student_answer, correct_answer)
            elif question_type == "essay":
                return await self._grade_essay(student_answer, correct_answer)
            else:
                raise ValueError(f"지원하지 않는 문제 유형: {question_type}")
                
        except Exception as e:
            self.logger.error(f"채점 중 오류: {str(e)}")
            raise
    
    async def _grade_short_answer(self, student_answer: str, correct_answer: str) -> Dict[str, Any]:
        """
        단답형 문제 채점
        """
        # 정답 비교 로직 (대소문자 무시, 공백 제거 등)
        normalized_student = student_answer.strip().lower()
        normalized_correct = correct_answer.strip().lower()
        
        is_correct = normalized_student == normalized_correct
        score = 100 if is_correct else 0
        
        feedback = "정답입니다!" if is_correct else f"오답입니다. 정답: {correct_answer}"
        
        return {
            "score": score,
            "max_score": 100,
            "is_correct": is_correct,
            "feedback": feedback
        }
    
    async def _grade_multiple_choice(self, student_answer: str, correct_answer: str) -> Dict[str, Any]:
        """
        객관식 문제 채점
        """
        is_correct = student_answer.strip().upper() == correct_answer.strip().upper()
        score = 100 if is_correct else 0
        
        return {
            "score": score,
            "max_score": 100,
            "is_correct": is_correct,
            "feedback": "정답" if is_correct else "오답"
        }
    
    async def _grade_essay(self, student_answer: str, correct_answer: str) -> Dict[str, Any]:
        """
        서술형 문제 채점 (향후 AI 모델 활용)
        """
        # 현재는 간단한 키워드 매칭으로 구현
        # 추후 AI 모델을 활용한 의미적 유사도 계산으로 개선
        
        correct_keywords = set(correct_answer.lower().split())
        student_keywords = set(student_answer.lower().split())
        
        matching_keywords = correct_keywords.intersection(student_keywords)
        similarity_ratio = len(matching_keywords) / len(correct_keywords) if correct_keywords else 0
        
        score = int(similarity_ratio * 100)
        
        return {
            "score": score,
            "max_score": 100,
            "is_correct": score >= 70,  # 70점 이상을 정답으로 인정
            "feedback": f"키워드 일치율: {similarity_ratio:.2%}"
        }
