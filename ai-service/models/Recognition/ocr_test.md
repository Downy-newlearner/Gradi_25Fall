```python
conda create -n ocr python=3.11 -y
conda activate ocr

pip install "numpy<2"
pip install pytesseract easyocr paddleocr paddlepaddle cnocr onnxruntime

```

```Linux
sudo apt update
sudo apt install tesseract-ocr
```