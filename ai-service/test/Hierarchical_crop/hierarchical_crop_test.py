import logging
import time
import csv
import json
from pathlib import Path
from services.hierarchical_crop import HierarchicalCropPipeline

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
    model_dir = current_dir.parent.parent / "models" / "Detection" / "Model_routing_1104"

    logger.info("=" * 60)
    logger.info("계층적 크롭 파이프라인 (3-4단계만 수행) 실험 시작")
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
        logger.info(f"[{idx + 1}/{len(image_files)}] 이미지 처리 중: {Path(image_path).name}")
        logger.info(f"{'#' * 60}")

        try:
            result = pipeline.process_page(str(image_path), output_dir)
            all_results.append(result)
            logger.info(f"✅ 페이지 '{result['page_name']}' 처리 완료: {result['processing_time']:.2f}초")
        except Exception as e:
            logger.error(f"이미지 처리 실패: {image_path}")
            logger.error(f"에러: {e}", exc_info=True)
            continue

    total_end_time = time.time()
    total_processing_time = total_end_time - total_start_time

    # 요약 및 결과 저장
    print_summary(all_results, output_dir, total_processing_time)
    save_results_csv(all_results, output_dir)


def save_results_csv(all_results: list, output_dir: Path):
    """
    HierarchicalCropPipeline에서 반환한 모든 key-value를 하나의 CSV에 저장
    (리스트/딕셔너리 값은 JSON 문자열로 변환)
    """
    csv_path = output_dir / "results_summary.csv"
    output_dir.mkdir(parents=True, exist_ok=True)

    if not all_results:
        logger.warning("⚠️ 저장할 결과가 없습니다.")
        return

    # 모든 결과의 key를 수집하여 통합 헤더 생성
    all_keys = set()
    for r in all_results:
        all_keys.update(r.keys())
    headers = sorted(all_keys)

    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=headers)
        writer.writeheader()

        for r in all_results:
            row = {}
            for k in headers:
                v = r.get(k, "")
                if isinstance(v, (list, dict)):
                    v = json.dumps(v, ensure_ascii=False)  # 리스트나 딕셔너리 → 문자열로 변환
                row[k] = v
            writer.writerow(row)

    logger.info(f"\n📄 CSV 결과 저장 완료: {csv_path}")
    logger.info(f"총 {len(all_results)}개 페이지 결과가 저장되었습니다.")


def print_summary(all_results: list, output_dir: Path, total_processing_time: float):
    """실험 결과 요약 출력"""
    logger.info("\n\n" + "=" * 60)
    logger.info("전체 처리 결과 요약")
    logger.info("=" * 60)

    total_pages = len(all_results)
    total_sections = sum(len(r.get("sections", [])) for r in all_results)

    logger.info(f"  처리된 페이지 수: {total_pages}")
    logger.info(f"  총 Section 수: {total_sections}")
    logger.info(f"  전체 처리 시간: {total_processing_time:.2f}초 ({total_processing_time / 60:.2f}분)")

    if all_results:
        avg_time = sum(r.get("processing_time", 0.0) for r in all_results) / len(all_results)
        logger.info(f"  페이지당 평균 처리 시간: {avg_time:.2f}초")

    logger.info(f"\n📁 결과 CSV: {output_dir / 'results_summary.csv'}")
    logger.info(f"📁 로그 파일: {log_file}")
    logger.info("=" * 60)
    logger.info("모든 실험이 완료되었습니다.")
    logger.info("=" * 60)


if __name__ == "__main__":
    main()

# 파일 실행: python -m test.Hierarchical_crop.hierarchical_crop_test