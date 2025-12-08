import pytesseract
from PIL import Image
import re

class TesseractOCRModel:
    def __init__(self):
        # Tesseract 설정 (필요시 경로 지정)
        # pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
        pass
    
    def extract_number(self, image_path):
        """이미지에서 숫자를 추출합니다."""
        try:
            img = Image.open(image_path)
            # 숫자만 인식하도록 설정
            text = pytesseract.image_to_string(img, config='--psm 6 digits')
            # 숫자만 추출
            numbers = re.findall(r'\d+', text)
            if numbers:
                return numbers[0]  # 첫 번째 숫자 반환
            return ""
        except Exception as e:
            print(f"Tesseract Error processing {image_path}: {e}")
            return ""