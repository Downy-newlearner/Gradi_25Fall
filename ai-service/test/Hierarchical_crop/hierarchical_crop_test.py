# yolo_test.py
import logging
import time
from pathlib import Path
from test.Hierarchical_crop.hierarchical_crop import HierarchicalCropPipeline

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
    model_dir_1104 = current_dir.parent.parent / "models" / "Detection" / "legacy" / "Model_routing_1104"
    model_dir_1004 = current_dir.parent.parent / "models" / "Detection" / "legacy" / "Model_routing_1004"
    
    # ✨ answer_1과 answer_2용 ResNet 모델 경로 분리
    resnet_answer_1_path = current_dir.parent.parent / "models" / "Classification" / "answer_1_resnet.pth"
    resnet_answer_2_path = current_dir.parent.parent / "models" / "Classification" / "answer_2_resnet.pth"

    # 답지 파일 경로
    answer_key_path = current_dir / "answers" / "answer.txt"
    
    # 답지 파일이 없으면 None으로 설정 (모든 페이지 처리)
    if not answer_key_path.exists():
        logger.warning(f"답지 파일을 찾을 수 없습니다: {answer_key_path}")
        logger.warning("모든 페이지를 처리합니다.")
        answer_key_path = None

    logger.info("=" * 60)
    logger.info("계층적 크롭 파이프라인 (answer_2 우선 + ResNet 분류) 실험 시작")
    logger.info("=" * 60)
    logger.info(f"입력 디렉토리: {input_images_dir}")
    logger.info(f"출력 디렉토리: {output_dir}")
    logger.info(f"1104 모델 디렉토리: {model_dir_1104}")
    logger.info(f"1004 모델 디렉토리: {model_dir_1004}")
    logger.info(f"answer_1 ResNet 모델: {resnet_answer_1_path}")  # ✨
    logger.info(f"answer_2 ResNet 모델: {resnet_answer_2_path}")  # ✨
    logger.info(f"답지 파일: {answer_key_path}")

    # 파이프라인 초기화 (두 개의 ResNet 모델 경로 전달)
    pipeline = HierarchicalCropPipeline(
        str(model_dir_1104), 
        str(model_dir_1004),
        section_padding=50,
        answer_key_path=str(answer_key_path) if answer_key_path else None,
        resnet_answer_1_path=str(resnet_answer_1_path) if resnet_answer_1_path.exists() else None,  # ✨
        resnet_answer_2_path=str(resnet_answer_2_path) if resnet_answer_2_path.exists() else None   # ✨
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
    save_none_analysis(all_results, output_dir)
    save_answer_source_analysis(all_results, output_dir)  # ✨ answer_source 통계 추가
    save_crop_failure_analysis(all_results, output_dir)
    check_missing_sections_against_answer_key(all_results, output_dir, pipeline.answer_key)


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
    resnet_used_count = 0  # ✨ ResNet 사용 횟수
    answer_2_count = 0  # ✨ answer_2 사용 횟수
    
    for result in all_results:
        for section in result.get("sections", []):
            if section.get("answer_number") is None:
                none_count += 1
            if section.get("used_resnet", False):  # ✨ ResNet 사용 여부
                resnet_used_count += 1
            answer_source = section.get("answer_source", "")
            # None 체크 추가
            if answer_source and answer_source.startswith("answer_2"):
                answer_2_count += 1
    
    logger.info(f"None 답안: {none_count}개 ({none_count/total_lines*100:.1f}%)")
    logger.info(f"ResNet 사용: {resnet_used_count}개 ({resnet_used_count/total_lines*100:.1f}%)")  # ✨
    logger.info(f"answer_2 사용: {answer_2_count}개 ({answer_2_count/total_lines*100:.1f}%)")  # ✨


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
                    'problem_crop_path': section.get('problem_crop_path'),
                    'used_resnet': section.get('used_resnet', False),  # ✨
                    'resnet_failed': section.get('resnet_failed', False),  # ✨
                    'answer_source': section.get('answer_source', '')  # ✨
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
        f.write("None 답안 디버깅 분석 (answer_2 우선 + ResNet)\n")
        f.write("=" * 80 + "\n\n")
        f.write(f"총 {len(none_cases)}개의 None 답안 발견\n\n")
        
        # 원인별 통계
        answer_1_missing = sum(1 for case in none_cases if case['debug_info'].get('answer_1_count', 0) == 0)
        answer_2_missing = sum(1 for case in none_cases if case['debug_info'].get('answer_2_count', 0) == 0)
        resnet_tried = sum(1 for case in none_cases if case['used_resnet'])  # ✨
        resnet_failed = sum(1 for case in none_cases if case['resnet_failed'])  # ✨
        
        f.write("📊 원인별 통계:\n")
        f.write(f"  - answer_1 미검출: {answer_1_missing}개\n")
        f.write(f"  - answer_2 미검출: {answer_2_missing}개\n")
        f.write(f"  - ResNet 시도: {resnet_tried}개 ({resnet_tried/len(none_cases)*100:.1f}%)\n")  # ✨
        f.write(f"  - ResNet도 실패: {resnet_failed}개 ({resnet_failed/len(none_cases)*100:.1f}%)\n")  # ✨
        f.write("\n")
        
        for i, case in enumerate(none_cases, 1):
            f.write(f"\n{'='*80}\n")
            f.write(f"[{i}] 페이지: {case['page_name']} (페이지번호: {case['page_num']})\n")
            f.write(f"    Section: {case['section_idx']}, 문제번호: {case['problem_number']}\n")
            f.write(f"{'-'*80}\n")
            
            debug = case['debug_info']
            answer_1_count = debug.get('answer_1_count', 0)
            answer_2_count = debug.get('answer_2_count', 0)
            
            f.write(f"  📋 검출 정보:\n")
            f.write(f"     answer_1 검출 개수: {answer_1_count}\n")
            f.write(f"     answer_2 검출 개수: {answer_2_count}\n")
            f.write(f"     ResNet 시도: {'예' if case['used_resnet'] else '아니오'}\n")  # ✨
            f.write(f"     answer_source: {case['answer_source']}\n")  # ✨
            if case['used_resnet']:
                f.write(f"     ResNet 결과: {'실패' if case['resnet_failed'] else '성공했으나 None'}\n")  # ✨
            f.write("\n")
            
            # 원인 분석
            f.write(f"  🔍 원인 분석:\n")
            if answer_2_count == 0 and answer_1_count == 0:
                f.write(f"     ❌ answer_1과 answer_2 모두 검출되지 않음 (1104 모델 문제)\n")
                f.write(f"     → 해결방법: 1104 모델 재학습 또는 confidence threshold 조정\n")
            elif answer_2_count > 0 and case['answer_source'] == 'answer_2_failed':
                f.write(f"     ❌ answer_2는 검출되었으나 ResNet 분류 실패\n")
                f.write(f"     → 해결방법: answer_2 ResNet 모델 재학습\n")
            elif answer_1_count > 0 and case['answer_source'] == 'answer_1_failed':
                f.write(f"     ❌ answer_1은 검출되었으나 ResNet 분류 실패\n")
                f.write(f"     → 해결방법: answer_1 ResNet 모델 재학습\n")
            else:
                f.write(f"     ⚠️ 원인 불명 (디버깅 필요)\n")
            
            # 파일 경로
            f.write(f"\n  📁 관련 파일:\n")
            f.write(f"     Section 이미지: {case['section_crop_path']}\n")
            if case['problem_crop_path']:
                f.write(f"     문제번호 이미지: {case['problem_crop_path']}\n")
            else:
                f.write(f"     문제번호 이미지: (미생성 - 문제번호 미검출)\n")
    
    logger.info(f"📊 None 디버깅 분석 저장 완료: {analysis_path}")
    logger.info(f"   총 {len(none_cases)}개 None 케이스 분석")


def save_answer_source_analysis(all_results: list, output_dir: Path):
    """
    ✨ answer_source별 통계를 별도 파일로 저장
    """
    analysis_path = output_dir.parent.parent / "answers" / "answer_source_analysis.txt"
    
    source_stats = {
        'answer_2_resnet': [],
        'answer_1_resnet': [],
        'answer_1_yolo': [],
        'answer_2_failed': [],
        'answer_1_failed': [],
        'no_answer_detected': [],
        'other': []
    }
    
    total_sections = 0
    
    for result in all_results:
        page_name = result.get("page_name", "")
        page_num_ocr = result.get("page_number_ocr", "")
        sections = result.get("sections", [])
        total_sections += len(sections)
        
        for section in sections:
            answer_source = section.get("answer_source", "")
            answer_number = section.get("answer_number")
            
            case = {
                'page_name': page_name,
                'page_num': page_num_ocr,
                'section_idx': section.get('section_idx'),
                'problem_number': section.get('problem_number_ocr'),
                'answer': answer_number,
                'confidence': section.get('resnet_confidence', 0.0)
            }
            
            if answer_source in source_stats:
                source_stats[answer_source].append(case)
            else:
                source_stats['other'].append(case)
    
    with open(analysis_path, "w", encoding="utf-8") as f:
        f.write("=" * 80 + "\n")
        f.write("답안 출처(answer_source)별 통계\n")
        f.write("=" * 80 + "\n\n")
        
        f.write(f"총 Section 수: {total_sections}개\n\n")
        
        f.write("📊 출처별 통계:\n")
        for source, cases in source_stats.items():
            if cases:
                percentage = len(cases) / total_sections * 100
                f.write(f"  - {source}: {len(cases)}개 ({percentage:.1f}%)\n")
        f.write("\n")
        
        # 성공률 계산
        success_sources = ['answer_2_resnet', 'answer_1_resnet', 'answer_1_yolo']
        success_count = sum(len(source_stats[s]) for s in success_sources)
        success_rate = success_count / total_sections * 100 if total_sections > 0 else 0
        
        f.write(f"✅ 전체 성공률: {success_count}/{total_sections} ({success_rate:.1f}%)\n")
        f.write(f"❌ 전체 실패율: {total_sections - success_count}/{total_sections} ({100 - success_rate:.1f}%)\n\n")
        
        # answer_2 우선 전략 효과
        answer_2_count = len(source_stats['answer_2_resnet'])
        if answer_2_count > 0:
            f.write(f"🎯 answer_2 우선 전략:\n")
            f.write(f"  - answer_2로 해결: {answer_2_count}개 ({answer_2_count/total_sections*100:.1f}%)\n")
            f.write(f"  - answer_2 ResNet 평균 신뢰도: ")
            avg_conf = sum(c['confidence'] for c in source_stats['answer_2_resnet']) / len(source_stats['answer_2_resnet'])
            f.write(f"{avg_conf:.4f}\n\n")
        
        # 상세 케이스
        for source, cases in source_stats.items():
            if cases:
                f.write(f"\n{'='*80}\n")
                f.write(f"{source.upper()} ({len(cases)}개)\n")
                f.write(f"{'='*80}\n")
                
                for i, case in enumerate(cases[:10], 1):  # 최대 10개만 표시
                    f.write(f"\n[{i}] 페이지: {case['page_name']}, ")
                    f.write(f"Section: {case['section_idx']}, ")
                    f.write(f"문제: {case['problem_number']}, ")
                    f.write(f"답: {case['answer']}")
                    if case['confidence'] > 0:
                        f.write(f", 신뢰도: {case['confidence']:.4f}")
                    f.write("\n")
                
                if len(cases) > 10:
                    f.write(f"\n... (외 {len(cases) - 10}개)\n")
    
    logger.info(f"📊 answer_source 분석 저장 완료: {analysis_path}")
    logger.info(f"   answer_2 ResNet: {len(source_stats['answer_2_resnet'])}개")
    logger.info(f"   answer_1 ResNet: {len(source_stats['answer_1_resnet'])}개")
    logger.info(f"   answer_1 YOLO: {len(source_stats['answer_1_yolo'])}개")


def save_crop_failure_analysis(all_results: list, output_dir: Path):
    """
    Section crop 실패 케이스를 분석하여 별도 파일로 저장
    """
    analysis_path = output_dir.parent.parent / "answers" / "crop_failure_analysis.txt"
    
    crop_failure_cases = []
    total_expected_sections = 0
    total_actual_files = 0
    
    for result in all_results:
        page_name = result.get("page_name", "")
        sections = result.get("sections", [])
        total_expected_sections += len(sections)
        
        # 실제 저장된 파일 확인
        sections_dir = output_dir / page_name / "sections"
        if sections_dir.exists():
            actual_files = sorted(sections_dir.glob("section_*.jpg"))
            total_actual_files += len(actual_files)
        
        for section in sections:
            if not section.get("crop_success", True):
                crop_failure_cases.append({
                    'page_name': page_name,
                    'section_idx': section.get('section_idx'),
                    'failure_reason': section.get('crop_failure_reason', 'unknown'),
                    'debug_info': section.get('debug_info', {})
                })
    
    logger.info(f"\n📊 Section 파일 검증:")
    logger.info(f"   예상 section 총 개수: {total_expected_sections}")
    logger.info(f"   실제 저장된 파일 개수: {total_actual_files}")
    
    if not crop_failure_cases:
        logger.info("✅ Section crop 실패 케이스가 없습니다!")
        with open(analysis_path, "w", encoding="utf-8") as f:
            f.write("✅ 모든 Section이 정상적으로 crop되었습니다!\n")
        return
    
    with open(analysis_path, "w", encoding="utf-8") as f:
        f.write("=" * 80 + "\n")
        f.write("Section Crop 실패 케이스 분석\n")
        f.write("=" * 80 + "\n\n")
        f.write(f"총 {len(crop_failure_cases)}개의 Section crop 실패 발견\n\n")
        
        for i, case in enumerate(crop_failure_cases, 1):
            f.write(f"[{i}] 페이지: {case['page_name']}, Section: {case['section_idx']}\n")
            f.write(f"    실패 원인: {case['failure_reason']}\n\n")
    
    logger.info(f"📊 Crop 실패 분석 저장 완료: {analysis_path}")


def check_missing_sections_against_answer_key(all_results: list, output_dir: Path, answer_key: dict):
    """
    답지와 실제 처리된 section을 비교하여 누락된 문제를 찾아냄
    """
    if not answer_key:
        logger.info("답지가 없어 누락 검출을 건너뜁니다.")
        return
    
    analysis_path = output_dir.parent.parent / "answers" / "missing_sections_analysis.txt"
    
    missing_cases = []
    
    for result in all_results:
        page_num_ocr = result.get("page_number_ocr", "")
        sections = result.get("sections", [])
        
        if page_num_ocr not in answer_key:
            continue
        
        expected_problems = answer_key[page_num_ocr]
        expected_count = len(expected_problems)
        actual_count = len(sections)
        
        if expected_count != actual_count:
            missing_cases.append({
                'page_name': result.get("page_name"),
                'page_num': page_num_ocr,
                'expected_count': expected_count,
                'actual_count': actual_count
            })
    
    if not missing_cases:
        logger.info("✅ 모든 페이지의 문제 수가 답지와 일치합니다!")
        return
    
    with open(analysis_path, "w", encoding="utf-8") as f:
        f.write("=" * 80 + "\n")
        f.write("답지 기반 누락 Section 분석\n")
        f.write("=" * 80 + "\n\n")
        f.write(f"총 {len(missing_cases)}개 페이지에서 불일치 발견\n\n")
        
        for case in missing_cases:
            f.write(f"페이지: {case['page_name']}\n")
            f.write(f"  예상: {case['expected_count']}개, 실제: {case['actual_count']}개\n\n")
    
    logger.info(f"📊 답지 기반 누락 분석 저장 완료: {analysis_path}")


def print_summary(all_results: list, skipped_pages: list, output_dir: Path, total_processing_time: float):
    """실험 결과 요약 출력"""
    logger.info("\n\n" + "=" * 60)
    logger.info("전체 처리 결과 요약 (answer_2 우선 + ResNet)")
    logger.info("=" * 60)

    total_pages = len(all_results)
    total_sections = sum(len(r.get("sections", [])) for r in all_results)
    total_crop_failures = sum(r.get("crop_failure_count", 0) for r in all_results)
    
    # ✨ answer_source 통계
    source_counts = {
        'answer_2_resnet': 0,
        'answer_1_resnet': 0,
        'answer_1_yolo': 0,
        'failed': 0
    }
    
    for result in all_results:
        for section in result.get("sections", []):
            answer_source = section.get("answer_source", "")
            
            # None 체크 추가
            if not answer_source:
                source_counts['failed'] += 1
            elif answer_source.startswith("answer_2"):
                if answer_source == "answer_2_resnet":
                    source_counts['answer_2_resnet'] += 1
                else:
                    source_counts['failed'] += 1
            elif answer_source.startswith("answer_1"):
                if answer_source == "answer_1_resnet":
                    source_counts['answer_1_resnet'] += 1
                elif answer_source == "answer_1_yolo":
                    source_counts['answer_1_yolo'] += 1
                else:
                    source_counts['failed'] += 1
            else:
                source_counts['failed'] += 1

    logger.info(f"  처리된 페이지 수: {total_pages}")
    logger.info(f"  건너뛴 페이지 수: {len(skipped_pages)}")
    logger.info(f"  총 Section 수: {total_sections}")
    logger.info(f"  Section crop 실패: {total_crop_failures}개")
    logger.info(f"\n  📊 답안 출처 통계:")
    logger.info(f"     answer_2 ResNet: {source_counts['answer_2_resnet']}개 ({source_counts['answer_2_resnet']/total_sections*100:.1f}%)")
    logger.info(f"     answer_1 ResNet: {source_counts['answer_1_resnet']}개 ({source_counts['answer_1_resnet']/total_sections*100:.1f}%)")
    logger.info(f"     answer_1 YOLO: {source_counts['answer_1_yolo']}개 ({source_counts['answer_1_yolo']/total_sections*100:.1f}%)")
    logger.info(f"     실패: {source_counts['failed']}개 ({source_counts['failed']/total_sections*100:.1f}%)")
    logger.info(f"\n  전체 처리 시간: {total_processing_time:.2f}초 ({total_processing_time / 60:.2f}분)")

    logger.info(f"\n📁 결과 파일:")
    logger.info(f"   - results_summary.txt")
    logger.info(f"   - none_debug_analysis.txt")
    logger.info(f"   - answer_source_analysis.txt")
    logger.info(f"   - crop_failure_analysis.txt")
    logger.info(f"   - missing_sections_analysis.txt")
    logger.info("=" * 60)


if __name__ == "__main__":
    main()

# 파일 실행: python -m test.Hierarchical_crop.hierarchical_crop_test