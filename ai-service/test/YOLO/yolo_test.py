# yolo_test.py
import logging
import time
from pathlib import Path
from test.YOLO.yolo_test_crop import HierarchicalCropPipeline

# === 로깅 설정 ===
current_dir = Path(__file__).parent
log_file = current_dir / "ocr_results.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# 파일 출력 추가 (utf-8 인코딩)
file_handler = logging.FileHandler(log_file, encoding="utf-8")
file_handler.setLevel(logging.INFO)
file_formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
file_handler.setFormatter(file_formatter)
logger.addHandler(file_handler)

logger.info(f"✅ 로그 파일이 '{log_file}'로 저장됩니다.")


def main():
    """메인 실험 함수"""
    total_start_time = time.time()

    # 경로 설정
    input_images_dir = current_dir / "images" / "exp_images"
    output_dir = current_dir / "images" / "test_results"
    model_dir_1104 = current_dir.parent.parent / "models" / "Detection" / "Model_routing_1104"
    model_dir_1004 = current_dir.parent.parent / "models" / "Detection" / "Model_routing_1004"
    
    # 답지 파일 경로 (필요한 경우 수정)
    # 답지 형식: 페이지번호, 문제번호, 정답 (각 줄마다 쉼표로 구분)
    # 예: 1, 1, 3
    answer_key_path = current_dir / "answers" / "answer.txt"  # 답지 파일 경로
    
    # 답지 파일이 없으면 None으로 설정 (모든 페이지 처리)
    if not answer_key_path.exists():
        logger.warning(f"답지 파일을 찾을 수 없습니다: {answer_key_path}")
        logger.warning("모든 페이지를 처리합니다.")
        answer_key_path = None

    logger.info("=" * 60)
    logger.info("계층적 크롭 파이프라인 (개선 버전) 실험 시작")
    logger.info("=" * 60)
    logger.info(f"입력 디렉토리: {input_images_dir}")
    logger.info(f"출력 디렉토리: {output_dir}")
    logger.info(f"1104 모델 디렉토리: {model_dir_1104}")
    logger.info(f"1004 모델 디렉토리: {model_dir_1004}")
    logger.info(f"답지 파일: {answer_key_path}")

    # 파이프라인 초기화 (section_padding 증가, 답지 파일 추가)
    pipeline = HierarchicalCropPipeline(
        str(model_dir_1104), 
        str(model_dir_1004),
        section_padding=50,  # 20 → 50으로 증가
        answer_key_path=str(answer_key_path) if answer_key_path else None
    )

    # 이미지 파일 수집
    image_extensions = [".jpg", ".jpeg", ".png", ".bmp"]
    image_files = []
    for ext in image_extensions:
        image_files.extend(input_images_dir.glob(f"*{ext}"))
        image_files.extend(input_images_dir.glob(f"*{ext.upper()}"))

    image_files = sorted(image_files)
    logger.info(f"\n처리할 이미지: {len(image_files)}개")

    if not image_files:
        logger.warning(f"입력 디렉토리에 이미지가 없습니다: {input_images_dir}")
        return

    # 각 이미지 처리
    all_results = []
    skipped_pages = []
    
    for idx, image_path in enumerate(image_files):
        logger.info(f"\n\n{'#' * 60}")
        logger.info(f"[{idx + 1}/{len(image_files)}] 이미지 처리 중: {Path(image_path).name}")
        logger.info(f"{'#' * 60}")

        try:
            result = pipeline.process_page(str(image_path), output_dir)
            
            if result is None:
                # 답지에 없는 페이지
                skipped_pages.append(Path(image_path).name)
                logger.info(f"⏭️ 페이지 건너뜀 (답지에 없음)")
            else:
                all_results.append(result)
                logger.info(f"✅ 페이지 '{result['page_name']}' 처리 완료: {result['processing_time']:.2f}초")
        except Exception as e:
            logger.error(f"이미지 처리 실패: {image_path}")
            logger.error(f"에러: {e}", exc_info=True)
            continue

    total_end_time = time.time()
    total_processing_time = total_end_time - total_start_time

    # 요약 및 결과 저장
    print_summary(all_results, skipped_pages, output_dir, total_processing_time)
    save_results_txt(all_results, output_dir)
    save_none_analysis(all_results, output_dir)  # ✨ None 분석 추가


def save_results_txt(all_results: list, output_dir: Path):
    """
    TXT 파일에 페이지 번호, 문제 번호, 인식된 답을 한 줄씩 저장
    """
    txt_path = output_dir.parent.parent / "answers" / "results_summary.txt"
    output_dir.mkdir(parents=True, exist_ok=True)

    if not all_results:
        logger.warning("⚠️ 저장할 결과가 없습니다.")
        return

    with open(txt_path, "w", encoding="utf-8") as f:
        for result in all_results:
            page_name = result.get("page_name", "")
            page_num_ocr = result.get("page_number_ocr", "")
            sections = result.get("sections", [])
            
            for section in sections:
                problem_number = section.get("problem_number_ocr", "")
                answer_number = section.get("answer_number", "")
                
                # 이미지 파일명, 페이지 번호, 문제 번호, 답 번호를 쉼표로 구분하여 한 줄에 작성
                line = f"{page_name}, {page_num_ocr}, {problem_number}, {answer_number}\n"
                f.write(line)

    logger.info(f"\n📄 TXT 결과 저장 완료: {txt_path}")
    
    # 총 라인 수 계산
    total_lines = sum(len(r.get("sections", [])) for r in all_results)
    logger.info(f"총 {total_lines}개 문제 결과가 저장되었습니다.")
    
    # None 답안 통계
    none_count = 0
    for result in all_results:
        for section in result.get("sections", []):
            if section.get("answer_number") is None:
                none_count += 1
    
    logger.info(f"None 답안: {none_count}개 ({none_count/total_lines*100:.1f}%)")


def save_none_analysis(all_results: list, output_dir: Path):
    """
    None으로 저장된 답안의 상세 디버깅 정보를 별도 파일로 저장
    """
    analysis_path = output_dir.parent.parent / "answers" / "none_debug_analysis.txt"
    
    none_cases = []
    for result in all_results:
        page_name = result.get("page_name", "")
        page_num_ocr = result.get("page_number_ocr", "")
        sections = result.get("sections", [])
        
        for section in sections:
            if section.get("answer_number") is None:
                debug_info = section.get("debug_info", {})
                none_cases.append({
                    'page_name': page_name,
                    'page_num': page_num_ocr,
                    'section_idx': section.get('section_idx'),
                    'problem_number': section.get('problem_number_ocr'),
                    'debug_info': debug_info,
                    'section_crop_path': section.get('section_crop_path'),
                    'problem_crop_path': section.get('problem_crop_path')
                })
    
    if not none_cases:
        logger.info("✅ None 답안이 없습니다!")
        with open(analysis_path, "w", encoding="utf-8") as f:
            f.write("=" * 80 + "\n")
            f.write("None 답안 디버깅 분석\n")
            f.write("=" * 80 + "\n\n")
            f.write("✅ None 답안이 없습니다! 모든 문제가 정상적으로 인식되었습니다.\n")
        return
    
    with open(analysis_path, "w", encoding="utf-8") as f:
        f.write("=" * 80 + "\n")
        f.write("None 답안 디버깅 분석\n")
        f.write("=" * 80 + "\n\n")
        f.write(f"총 {len(none_cases)}개의 None 답안 발견\n\n")
        
        # 원인별 통계
        answer_1_missing = sum(1 for case in none_cases if case['debug_info'].get('answer_1_count', 0) == 0)
        class_missing = sum(1 for case in none_cases if case['debug_info'].get('class_count', 0) == 0)
        iou_zero = sum(1 for case in none_cases 
                      if case['debug_info'].get('answer_1_count', 0) > 0 
                      and case['debug_info'].get('class_count', 0) > 0 
                      and case['debug_info'].get('best_iou', 0) == 0)
        
        f.write("📊 원인별 통계:\n")
        f.write(f"  - answer_1 미검출: {answer_1_missing}개 ({answer_1_missing/len(none_cases)*100:.1f}%)\n")
        f.write(f"  - 숫자(1-5) 미검출: {class_missing}개 ({class_missing/len(none_cases)*100:.1f}%)\n")
        f.write(f"  - IoU 0 (위치 불일치): {iou_zero}개 ({iou_zero/len(none_cases)*100:.1f}%)\n")
        f.write("\n")
        
        for i, case in enumerate(none_cases, 1):
            f.write(f"\n{'='*80}\n")
            f.write(f"[{i}] 페이지: {case['page_name']} (페이지번호: {case['page_num']})\n")
            f.write(f"    Section: {case['section_idx']}, 문제번호: {case['problem_number']}\n")
            f.write(f"{'-'*80}\n")
            
            debug = case['debug_info']
            answer_1_count = debug.get('answer_1_count', 0)
            class_count = debug.get('class_count', 0)
            best_iou = debug.get('best_iou', 0.0)
            
            f.write(f"  📋 검출 정보:\n")
            f.write(f"     answer_1 검출 개수: {answer_1_count}\n")
            f.write(f"     숫자(1-5) 검출 개수: {class_count}\n")
            f.write(f"     최고 IoU: {best_iou:.4f}\n\n")
            
            # 원인 분석
            f.write(f"  🔍 원인 분석:\n")
            if answer_1_count == 0:
                f.write(f"     ❌ answer_1이 검출되지 않음 (1104 모델 문제)\n")
                f.write(f"     → 해결방법: 1104 모델 재학습 또는 confidence threshold 조정\n")
            elif class_count == 0:
                f.write(f"     ❌ 숫자(1-5)가 검출되지 않음 (1104 모델 문제)\n")
                f.write(f"     → 해결방법: 1104 모델 재학습 또는 confidence threshold 조정\n")
            elif best_iou == 0.0:
                f.write(f"     ❌ IoU가 0 (answer_1과 숫자의 위치가 겹치지 않음)\n")
                f.write(f"     → 해결방법: \n")
                f.write(f"        1. section padding을 50 → 70 또는 100으로 증가\n")
                f.write(f"        2. 검출 위치가 잘못되었을 가능성 → 모델 재학습\n")
            else:
                f.write(f"     ⚠️ 원인 불명 (디버깅 필요)\n")
            
            # IoU 상세 정보
            iou_details = debug.get('iou_details', [])
            if iou_details:
                f.write(f"\n  📐 IoU 상세 정보:\n")
                for detail in iou_details:
                    f.write(f"     - 숫자 {detail['class']}: IoU = {detail['iou']:.4f}, bbox = {detail['bbox']}\n")
            
            # 파일 경로
            f.write(f"\n  📁 관련 파일:\n")
            f.write(f"     Section 이미지: {case['section_crop_path']}\n")
            if case['problem_crop_path']:
                f.write(f"     문제번호 이미지: {case['problem_crop_path']}\n")
            else:
                f.write(f"     문제번호 이미지: (미생성 - 문제번호 미검출)\n")
    
    logger.info(f"📊 None 디버깅 분석 저장 완료: {analysis_path}")
    logger.info(f"   총 {len(none_cases)}개 None 케이스 분석")
    logger.info(f"   원인별: answer_1 미검출={answer_1_missing}, 숫자 미검출={class_missing}, IoU=0={iou_zero}")


def print_summary(all_results: list, skipped_pages: list, output_dir: Path, total_processing_time: float):
    """실험 결과 요약 출력"""
    logger.info("\n\n" + "=" * 60)
    logger.info("전체 처리 결과 요약")
    logger.info("=" * 60)

    total_pages = len(all_results)
    total_sections = sum(len(r.get("sections", [])) for r in all_results)

    logger.info(f"  처리된 페이지 수: {total_pages}")
    logger.info(f"  건너뛴 페이지 수: {len(skipped_pages)}")
    if skipped_pages:
        logger.info(f"    건너뛴 페이지: {', '.join(skipped_pages)}")
    logger.info(f"  총 Section 수: {total_sections}")
    logger.info(f"  전체 처리 시간: {total_processing_time:.2f}초 ({total_processing_time / 60:.2f}분)")

    if all_results:
        avg_time = sum(r.get("processing_time", 0.0) for r in all_results) / len(all_results)
        logger.info(f"  페이지당 평균 처리 시간: {avg_time:.2f}초")

    logger.info(f"\n📁 결과 TXT: {output_dir.parent.parent / 'answers' / 'results_summary.txt'}")
    logger.info(f"📊 None 디버깅: {output_dir.parent.parent / 'answers' / 'none_debug_analysis.txt'}")
    logger.info(f"📁 로그 파일: {log_file}")
    logger.info("=" * 60)
    logger.info("모든 실험이 완료되었습니다.")
    logger.info("=" * 60)


if __name__ == "__main__":
    main()

# 파일 실행: python -m test.YOLO.yolo_test