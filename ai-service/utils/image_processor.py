"""
이미지 처리 유틸리티
"""

import base64
import io
from PIL import Image
from typing import Tuple, Optional

class ImageProcessor:
    """
    이미지 처리 관련 유틸리티 클래스
    """
    
    def __init__(self):
        self.max_size = (1920, 1080)  # 최대 이미지 크기
        self.supported_formats = {'JPEG', 'PNG', 'JPG', 'WEBP'}
    
    def resize_image(self, image: Image.Image, max_size: Optional[Tuple[int, int]] = None) -> Image.Image:
        """
        이미지 크기 조정
        """
        if max_size is None:
            max_size = self.max_size
            
        image.thumbnail(max_size, Image.Resampling.LANCZOS)
        return image
    
    def validate_image_format(self, image: Image.Image) -> bool:
        """
        지원하는 이미지 형식인지 확인
        """
        return image.format in self.supported_formats
    
    def convert_to_base64(self, image: Image.Image, format: str = 'JPEG') -> str:
        """
        이미지를 base64 문자열로 변환
        """
        buffer = io.BytesIO()
        image.save(buffer, format=format)
        img_str = base64.b64encode(buffer.getvalue()).decode()
        return img_str
    
    def convert_from_base64(self, base64_string: str) -> Image.Image:
        """
        base64 문자열을 이미지로 변환
        """
        image_data = base64.b64decode(base64_string)
        image = Image.open(io.BytesIO(image_data))
        return image
    
    def preprocess_for_ocr(self, image: Image.Image) -> Image.Image:
        """
        OCR을 위한 이미지 전처리
        """
        # 그레이스케일 변환
        if image.mode != 'L':
            image = image.convert('L')
        
        # 이미지 크기 조정
        image = self.resize_image(image)
        
        return image
