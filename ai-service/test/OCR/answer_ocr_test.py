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


def get_images_with_labels(base_folder):
    """하위 폴더 구조에서 이미지와 정답 레이블을 추출합니다."""
    images_with_labels = []
    
    # 1, 2, 3, 4, 5 폴더를 순회
    for label in ['1', '2', '3', '4', '5']:
        folder_path = os.path.join(base_folder, label)
        if os.path.exists(folder_path):
            image_files = sorted([f for f in os.listdir(folder_path) 
                                if f.endswith(('.jpg', '.jpeg', '.png', '.JPG'))])
            
            for image_file in image_files:
                image_path = os.path.join(folder_path, image_file)
                relative_path = f"{label}/{image_file}"
                images_with_labels.append((relative_path, image_path, label))
    
    return images_with_labels


def process_answer_images(model, model_name, base_folder, output_file):
    """answer 폴더의 이미지를 처리하고 결과를 파일로 저장합니다."""
    images_with_labels = get_images_with_labels(base_folder)
    results = []
    
    print(f"\n{model_name} - Processing {len(images_with_labels)} images from {base_folder}...")
    
    for idx, (relative_path, image_path, true_label) in enumerate(images_with_labels, 1):
        extracted_number = model.extract_number(image_path)
        results.append((relative_path, extracted_number, true_label))
        
        if idx % 10 == 0 or idx == len(images_with_labels):
            print(f"  Progress: {idx}/{len(images_with_labels)}")
    
    # 결과를 파일로 저장
    with open(output_file, 'w', encoding='utf-8') as f:
        for relative_path, extracted_number in [(r[0], r[1]) for r in results]:
            f.write(f"{relative_path}, {extracted_number}\n")
    
    return results


def calculate_answer_accuracy(results):
    """폴더 기반 정답률을 계산합니다."""
    if not results:
        return 0.0
    
    correct = 0
    total = len(results)
    
    for relative_path, predicted, true_label in results:
        if predicted == true_label:
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
    
    # 폴더 경로 설정
    answer_1_folder = 'images/answer_1'
    answer_2_folder = 'images/answer_2'
    
    # 결과 저장용 리스트
    accuracy_results = []
    
    # 각 모델에 대해 처리
    for model_name, model in models.items():
        print(f"\n{'='*60}")
        print(f"Processing with {model_name.upper()}")
        print(f"{'='*60}")
        
        try:
            # Answer 1 처리
            answer_1_output_file = os.path.join(result_folder, f"{model_name}_answer_1_answer.txt")
            answer_1_results = process_answer_images(
                model, model_name, answer_1_folder, answer_1_output_file
            )
            answer_1_accuracy = calculate_answer_accuracy(answer_1_results)
            
            # Answer 2 처리
            answer_2_output_file = os.path.join(result_folder, f"{model_name}_answer_2_answer.txt")
            answer_2_results = process_answer_images(
                model, model_name, answer_2_folder, answer_2_output_file
            )
            answer_2_accuracy = calculate_answer_accuracy(answer_2_results)
            
            # 결과 저장
            accuracy_results.append({
                'model': model_name,
                'answer_1_accuracy': answer_1_accuracy,
                'answer_2_accuracy': answer_2_accuracy,
                'average_accuracy': (answer_1_accuracy + answer_2_accuracy) / 2
            })
            
            print(f"\n{model_name.upper()} Results:")
            print(f"  Answer 1 Accuracy: {answer_1_accuracy:.2f}%")
            print(f"  Answer 2 Accuracy: {answer_2_accuracy:.2f}%")
            print(f"  Average Accuracy: {(answer_1_accuracy + answer_2_accuracy) / 2:.2f}%")
            
        except Exception as e:
            print(f"Error with {model_name}: {e}")
            accuracy_results.append({
                'model': model_name,
                'answer_1_accuracy': 0.0,
                'answer_2_accuracy': 0.0,
                'average_accuracy': 0.0
            })
    
    # CSV 파일로 결과 저장
    csv_filename = os.path.join(result_folder, 'ocr_accuracy_results_answer.csv')
    with open(csv_filename, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = ['model', 'answer_1_accuracy', 'answer_2_accuracy', 'average_accuracy']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        
        writer.writeheader()
        for result in accuracy_results:
            writer.writerow(result)
    
    # 최종 결과 출력
    print(f"\n{'='*60}")
    print("FINAL RESULTS")
    print(f"{'='*60}")
    print(f"\n{'Model':<15} {'Answer 1 %':<15} {'Answer 2 %':<15} {'Average %':<15}")
    print("-" * 60)
    
    for result in accuracy_results:
        print(f"{result['model']:<15} "
              f"{result['answer_1_accuracy']:<15.2f} "
              f"{result['answer_2_accuracy']:<15.2f} "
              f"{result['average_accuracy']:<15.2f}")
    
    print(f"\nResults saved to {csv_filename}")


if __name__ == "__main__":
    main()