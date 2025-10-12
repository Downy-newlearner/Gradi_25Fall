import easyocr
import re

class EasyOCRModel:
    def __init__(self):
        self.reader = easyocr.Reader(['en'], gpu=False)
    
    def extract_number(self, image_path):
        """이미지에서 숫자를 추출합니다."""
        try:
            results = self.reader.readtext(image_path)
            # 모든 텍스트 결과를 합침
            text = ' '.join([result[1] for result in results])
            # 숫자만 추출
            numbers = re.findall(r'\d+', text)
            if numbers:
                return numbers[0]  # 첫 번째 숫자 반환
            return ""
        except Exception as e:
            print(f"EasyOCR Error processing {image_path}: {e}")
            return ""