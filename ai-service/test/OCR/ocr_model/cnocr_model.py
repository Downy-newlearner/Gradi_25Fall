import re
from cnocr import CnOcr
from pathlib import Path

class CNOCRModel:
    def __init__(self):
        # CnOcr 모델 초기화
        self.ocr = CnOcr()

    def extract_number(self, image_path):
        """이미지에서 숫자 추출"""
        try:
            image_path = str(Path(image_path).resolve())
            results = self.ocr.ocr(image_path)

            if isinstance(results, list):
                text = ''.join([
                    item['text'] for item in results
                    if isinstance(item, dict) and 'text' in item
                ])
            elif isinstance(results, dict) and 'text' in results:
                text = results['text']
            else:
                text = ""

            numbers = re.findall(r'\d+', text)
            return numbers[0] if numbers else ""
        except Exception as e:
            print(f"CNOCR Error processing {image_path}: {e}")
            return ""
