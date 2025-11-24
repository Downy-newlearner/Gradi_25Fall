# services/chapter_mapper.py
"""
챕터 매핑 유틸리티
- chapter.txt 파일에서 챕터 정보 로드
- 페이지 번호로 해당 chapter_id 조회
"""

import logging
import os
from typing import Dict, List, Optional, Tuple

logger = logging.getLogger(__name__)


class ChapterMapper:
    """페이지 번호를 chapter_id로 매핑하는 클래스"""
    
    def __init__(self, chapter_file_path: str = "DB/chapter.txt"):
        """
        Args:
            chapter_file_path: chapter.txt 파일 경로
        """
        self.chapter_file_path = chapter_file_path
        self.chapters: List[Dict] = []  # [{'chapter_id': '001', 'start_page': 9, 'end_page': 13}, ...]
        
        self._load_chapters()
    
    def _load_chapters(self) -> None:
        """chapter.txt 파일에서 챕터 정보 로드
        
        파일 형식: {chapter_id}, {시작 페이지}, {마지막 페이지}
        예: 001, 9, 13
        """
        if not os.path.exists(self.chapter_file_path):
            logger.warning(f"챕터 파일을 찾을 수 없습니다: {self.chapter_file_path}")
            return
        
        try:
            with open(self.chapter_file_path, 'r', encoding='utf-8') as f:
                for line_num, line in enumerate(f, 1):
                    line = line.strip()
                    
                    # 빈 줄 스킵
                    if not line:
                        continue
                    
                    # 주석 스킵 (선택적)
                    if line.startswith('#'):
                        continue
                    
                    parts = [p.strip() for p in line.split(',')]
                    
                    if len(parts) < 3:
                        logger.warning(f"챕터 파일 {line_num}번째 줄 형식 오류: {line}")
                        continue
                    
                    try:
                        chapter_id = parts[0]
                        start_page = int(parts[1])
                        end_page = int(parts[2])
                        
                        self.chapters.append({
                            'chapter_id': chapter_id,
                            'start_page': start_page,
                            'end_page': end_page
                        })
                        
                    except ValueError as e:
                        logger.warning(f"챕터 파일 {line_num}번째 줄 파싱 오류: {line} - {e}")
                        continue
            
            logger.info(f"✅ 챕터 정보 로드 완료: {len(self.chapters)}개 챕터")
            for ch in self.chapters:
                logger.debug(f"  - 챕터 {ch['chapter_id']}: 페이지 {ch['start_page']}-{ch['end_page']}")
                
        except Exception as e:
            logger.error(f"챕터 파일 로드 실패: {e}")
    
    def get_chapter_id(self, page_number: int) -> Optional[str]:
        """페이지 번호에 해당하는 chapter_id 반환
        
        Args:
            page_number: 페이지 번호 (정수)
            
        Returns:
            chapter_id 문자열 또는 None (해당 챕터가 없는 경우)
        """
        for chapter in self.chapters:
            if chapter['start_page'] <= page_number <= chapter['end_page']:
                return chapter['chapter_id']
        
        return None
    
    def get_chapter_id_from_str(self, page_number_str: Optional[str]) -> Optional[str]:
        """문자열 페이지 번호에 해당하는 chapter_id 반환
        
        Args:
            page_number_str: 페이지 번호 문자열
            
        Returns:
            chapter_id 문자열 또는 None
        """
        if not page_number_str:
            return None
        
        try:
            page_number = int(page_number_str)
            return self.get_chapter_id(page_number)
        except ValueError:
            logger.warning(f"페이지 번호 변환 실패: {page_number_str}")
            return None
    
    def get_chapter_id_as_int(self, page_number: int) -> int:
        """페이지 번호에 해당하는 chapter_id를 정수로 반환
        
        Args:
            page_number: 페이지 번호 (정수)
            
        Returns:
            chapter_id 정수 또는 0 (해당 챕터가 없는 경우)
        """
        chapter_id_str = self.get_chapter_id(page_number)
        
        if chapter_id_str is None:
            return 0
        
        try:
            return int(chapter_id_str)
        except ValueError:
            logger.warning(f"chapter_id를 정수로 변환할 수 없음: {chapter_id_str}")
            return 0
    
    def get_chapter_id_as_int_from_str(self, page_number_str: Optional[str]) -> int:
        """문자열 페이지 번호에 해당하는 chapter_id를 정수로 반환
        
        Args:
            page_number_str: 페이지 번호 문자열
            
        Returns:
            chapter_id 정수 또는 0
        """
        if not page_number_str:
            return 0
        
        try:
            page_number = int(page_number_str)
            return self.get_chapter_id_as_int(page_number)
        except ValueError:
            logger.warning(f"페이지 번호 변환 실패: {page_number_str}")
            return 0
    
    def reload(self) -> None:
        """챕터 정보 다시 로드"""
        self.chapters = []
        self._load_chapters()
    
    def __len__(self) -> int:
        """로드된 챕터 개수 반환"""
        return len(self.chapters)
    
    def __repr__(self) -> str:
        return f"ChapterMapper(chapters={len(self.chapters)}, file='{self.chapter_file_path}')"