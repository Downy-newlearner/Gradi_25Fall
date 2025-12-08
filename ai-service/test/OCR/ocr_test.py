import os
import sys
import csv
import time
from pathlib import Path

# ocr_model 폴더의 모델들 import
sys.path.append('ocr_model')
from easyocr_model import EasyOCRModel
from tesseract_model import TesseractOCRModel
from paddleocr_model import PaddleOCRModel
from cnocr_model import CNOCRModel


def load_ground_truth(file_path):
    """정답 파일을 로드합니다."""
    ground_truth = {}
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line:
                    parts = line.split(', ')
                    if len(parts) == 2:
                        filename = parts[0]
                        answer = parts[1]
                        ground_truth[filename] = answer
    except FileNotFoundError:
        print(f"Warning: {file_path} not found")
    return ground_truth


def process_images(model, model_name, image_folder, output_file):
    """이미지를 처리하고 결과를 파일로 저장합니다."""
    results = []
    image_files = sorted([f for f in os.listdir(image_folder) 
                         if f.endswith(('.jpg', '.jpeg', '.png', '.JPG'))])
    
    print(f"\n{model_name} - Processing {len(image_files)} images from {image_folder}...")
    
    for idx, image_file in enumerate(image_files, 1):
        image_path = os.path.join(image_folder, image_file)
        extracted_number = model.extract_number(image_path)
        results.append((image_file, extracted_number))
        
        if idx % 10 == 0 or idx == len(image_files):
            print(f"  Progress: {idx}/{len(image_files)}")
    
    # 결과를 파일로 저장
    with open(output_file, 'w', encoding='utf-8') as f:
        for filename, number in results:
            f.write(f"{filename}, {number}\n")
    
    return results


def calculate_accuracy(predictions, ground_truth):
    """정답률을 계산합니다."""
    if not ground_truth:
        return 0.0
    
    correct = 0
    total = 0
    
    for filename, predicted in predictions:
        if filename in ground_truth:
            total += 1
            if predicted == ground_truth[filename]:
                correct += 1
    
    accuracy = (correct / total * 100) if total > 0 else 0.0
    return accuracy


def main():
    # 결과 저장 폴더 생성
    result_folder = 'test_result'
    os.makedirs(result_folder, exist_ok=True)
    
    # 모델 초기화
    models = {
        'easyocr': EasyOCRModel(),
        'tesseract': TesseractOCRModel(),
        'paddleocr': PaddleOCRModel(),
        'cnocr': CNOCRModel()
    }
    
    # 폴더 및 파일 경로 설정
    page_number_folder = 'images/page_number'
    problem_number_folder = 'images/problem_number'
    page_number_gt_file = 'images/page_number.txt'
    problem_number_gt_file = 'images/problem_number.txt'
    
    # 정답 데이터 로드
    print("Loading ground truth data...")
    page_number_gt = load_ground_truth(page_number_gt_file)
    problem_number_gt = load_ground_truth(problem_number_gt_file)
    
    # 결과 저장용 리스트
    accuracy_results = []
    
    # 각 모델에 대해 처리
    for model_name, model in models.items():
        print(f"\n{'='*60}")
        print(f"Processing with {model_name.upper()}")
        print(f"{'='*60}")
        
        try:
            # Page number 처리
            page_output_file = os.path.join(result_folder, f"{model_name}_page_number.txt")
            page_predictions = process_images(
                model, model_name, page_number_folder, page_output_file
            )
            page_accuracy = calculate_accuracy(page_predictions, page_number_gt)
            
            # Problem number 처리
            problem_output_file = os.path.join(result_folder, f"{model_name}_problem_number.txt")
            problem_predictions = process_images(
                model, model_name, problem_number_folder, problem_output_file
            )
            problem_accuracy = calculate_accuracy(problem_predictions, problem_number_gt)
            
            # 결과 저장
            accuracy_results.append({
                'model': model_name,
                'page_number_accuracy': page_accuracy,
                'problem_number_accuracy': problem_accuracy,
                'average_accuracy': (page_accuracy + problem_accuracy) / 2
            })
            
            print(f"\n{model_name.upper()} Results:")
            print(f"  Page Number Accuracy: {page_accuracy:.2f}%")
            print(f"  Problem Number Accuracy: {problem_accuracy:.2f}%")
            print(f"  Average Accuracy: {(page_accuracy + problem_accuracy) / 2:.2f}%")
            
        except Exception as e:
            print(f"Error with {model_name}: {e}")
            accuracy_results.append({
                'model': model_name,
                'page_number_accuracy': 0.0,
                'problem_number_accuracy': 0.0,
                'average_accuracy': 0.0
            })
    
    # CSV 파일로 결과 저장
    csv_filename = os.path.join(result_folder, 'ocr_accuracy_results.csv')
    with open(csv_filename, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = ['model', 'page_number_accuracy', 'problem_number_accuracy', 'average_accuracy']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        
        writer.writeheader()
        for result in accuracy_results:
            writer.writerow(result)
    
    # 최종 결과 출력
    print(f"\n{'='*60}")
    print("FINAL RESULTS")
    print(f"{'='*60}")
    print(f"\n{'Model':<15} {'Page Num %':<15} {'Problem Num %':<15} {'Average %':<15}")
    print("-" * 60)
    
    for result in accuracy_results:
        print(f"{result['model']:<15} "
              f"{result['page_number_accuracy']:<15.2f} "
              f"{result['problem_number_accuracy']:<15.2f} "
              f"{result['average_accuracy']:<15.2f}")
    
    print(f"\nResults saved to {csv_filename}")


if __name__ == "__main__":
    main()