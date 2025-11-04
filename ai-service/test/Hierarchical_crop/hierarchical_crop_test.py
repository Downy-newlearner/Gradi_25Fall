import logging
from pathlib import Path
from services.hierarchical_crop import HierarchicalCropPipeline

# === 로깅 설정 ===
current_dir = Path(__file__).parent
log_file = current_dir / "ocr_results.log"

# 기본 설정 (콘솔 출력)
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

    # 경로 설정
    input_images_dir = current_dir / "images" / "exp_images"
    output_dir = current_dir / "images" / "test_results"
    model_dir = current_dir.parent.parent / "models" / "Detection" / "Model_routing_1004"

    logger.info("=" * 60)
    logger.info("계층적 크롭 파이프라인 실험 시작")
    logger.info("=" * 60)
    logger.info(f"입력 디렉토리: {input_images_dir}")
    logger.info(f"출력 디렉토리: {output_dir}")
    logger.info(f"모델 디렉토리: {model_dir}")

    # 파이프라인 초기화
    pipeline = HierarchicalCropPipeline(str(model_dir))

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
    for idx, image_path in enumerate(image_files):
        logger.info(f"\n\n{'#' * 60}")
        logger.info(f"[{idx + 1}/{len(image_files)}] 이미지 처리 중")
        logger.info(f"{'#' * 60}")

        try:
            result = pipeline.process_page(str(image_path), output_dir)
            all_results.append(result)
        except Exception as e:
            logger.error(f"이미지 처리 실패: {image_path}")
            logger.error(f"에러: {e}", exc_info=True)
            continue

    # 전체 결과 요약
    print_summary(all_results, output_dir)


def print_summary(all_results: list, output_dir: Path):
    """실험 결과 요약 출력"""

    logger.info("\n\n" + "=" * 60)
    logger.info("전체 처리 결과 요약")
    logger.info("=" * 60)

    # 기본 통계
    total_sections = sum(len(r["sections"]) for r in all_results)
    total_problems = sum(
        len(section.get("problem_numbers_ocr", []))
        for r in all_results
        for section in r["sections"]
    )
    
    # 새로운 클래스 통계
    new_classes = ['1', '2', '3', '4', '5']
    total_new_classes = {
        cls: sum(
            len(section.get(f"class_{cls}", []))
            for r in all_results
            for section in r["sections"]
        )
        for cls in new_classes
    }

    logger.info(f"\n[기본 통계]")
    logger.info(f"  처리된 페이지: {len(all_results)}개")
    logger.info(f"  총 Section 수: {total_sections}개")
    logger.info(f"  총 문제번호 인식: {total_problems}개")
    
    # 새로운 클래스별 통계 출력
    logger.info(f"\n[새로운 클래스 검출 통계]")
    for cls in new_classes:
        logger.info(f"  클래스 {cls}: {total_new_classes[cls]}개")
    
    logger.info(f"\n  출력 위치: {output_dir}")

    # 페이지별 상세 결과
    logger.info(f"\n[페이지별 OCR 결과]")
    for result in all_results:
        page_name = result["page_name"]
        page_num = result.get("page_number_ocr", "N/A")

        logger.info(f"\n📄 페이지: {page_name}")
        logger.info(f"   페이지 번호: {page_num}")

        for section in result["sections"]:
            section_idx = section["section_idx"]
            problem_ocrs = section.get("problem_numbers_ocr", [])

            if problem_ocrs:
                problem_numbers = [p["number"] for p in problem_ocrs]
                logger.info(f"   📌 Section {section_idx}: {problem_numbers}")

                # 상세 정보
                for p in problem_ocrs:
                    logger.info(
                        f"      • 문제 {p['number']}: confidence={p['confidence']:.3f}"
                    )
            
            # 새로운 클래스 정보 출력
            new_class_counts = {}
            for cls in new_classes:
                count = len(section.get(f"class_{cls}", []))
                if count > 0:
                    new_class_counts[cls] = count
            
            if new_class_counts:
                class_info = ", ".join([f"클래스 {cls}: {cnt}개" for cls, cnt in new_class_counts.items()])
                logger.info(f"      🔹 {class_info}")

    # 성공률 분석
    logger.info(f"\n[인식 성공률]")
    pages_with_page_num = sum(1 for r in all_results if r.get("page_number_ocr"))
    page_num_success_rate = (
        pages_with_page_num / len(all_results) * 100 if all_results else 0
    )

    sections_with_problems = sum(
        1
        for r in all_results
        for section in r["sections"]
        if section.get("problem_numbers_ocr")
    )
    problem_success_rate = (
        sections_with_problems / total_sections * 100 if total_sections else 0
    )
    
    # 새로운 클래스가 검출된 섹션 수
    sections_with_new_classes = sum(
        1
        for r in all_results
        for section in r["sections"]
        if any(section.get(f"class_{cls}", []) for cls in new_classes)
    )
    new_class_success_rate = (
        sections_with_new_classes / total_sections * 100 if total_sections else 0
    )

    logger.info(
        f"  페이지 번호 인식 성공: {pages_with_page_num}/{len(all_results)} ({page_num_success_rate:.1f}%)"
    )
    logger.info(
        f"  문제번호 포함 Section: {sections_with_problems}/{total_sections} ({problem_success_rate:.1f}%)"
    )
    logger.info(
        f"  새로운 클래스 포함 Section: {sections_with_new_classes}/{total_sections} ({new_class_success_rate:.1f}%)"
    )

    logger.info("\n" + "=" * 60)
    logger.info("모든 실험이 완료되었습니다.")
    logger.info("=" * 60)
    logger.info(f"📁 전체 로그 파일: {log_file}")


if __name__ == "__main__":
    main()

# 파일 실행: python -m test.Hierarchical_crop.hierarchical_crop_test