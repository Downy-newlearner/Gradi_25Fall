import re
import logging
from paddleocr import PaddleOCR

# PaddleOCR 로그 최소화
logging.getLogger('paddleocr').setLevel(logging.WARNING)

class PaddleOCRModel:
    def __init__(self):
        # PaddleOCR 초기화
        self.ocr = PaddleOCR(use_angle_cls=True, lang='en')

    def extract_number(self, image_path):
        """이미지에서 숫자만 추출"""
        try:
            result = self.ocr.ocr(image_path)

            texts = []
            # PaddleOCR 버전별 결과 구조 대응
            if isinstance(result, list):
                for item in result:
                    if not item:
                        continue
                    if isinstance(item, list):
                        for line in item:
                            if isinstance(line, (list, tuple)) and len(line) > 1:
                                text_part = line[1][0] if isinstance(line[1], (list, tuple)) else line[1]
                                texts.append(str(text_part))
                    elif isinstance(item, (list, tuple)) and len(item) > 1:
                        text_part = item[1][0] if isinstance(item[1], (list, tuple)) else item[1]
                        texts.append(str(text_part))

            text = " ".join(texts)
            numbers = re.findall(r'\d+', text)
            return numbers[0] if numbers else ""
        except Exception as e:
            print(f"PaddleOCR Error processing {image_path}: {e}")
            return ""
