#!/usr/bin/env python3
"""
HierarchicalCropPipeline 테스트 스크립트
단일 이미지를 처리하고 결과를 검증합니다.
"""

import sys
import os
from pathlib import Path
import json
import logging

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def print_section_result(section: dict, section_idx: int):
    """Section 처리 결과를 보기 좋게 출력"""
    print(f"\n{'='*60}")
    print(f"Section {section_idx}")
    print(f"{'='*60}")
    
    # 문제번호
    problem_num = section.get('problem_number_ocr', 'N/A')
    problem_override = section.get('problem_number_override', False)
    if problem_override:
        print(f"📋 문제번호: {problem_num} (답지 기반 할당)")
    else:
        print(f"📋 문제번호: {problem_num}")
    
    # 답안
    answer = section.get('answer_number', 'N/A')
    answer_source = section.get('answer_source', 'N/A')
    print(f"✅ 정답: {answer} (출처: {answer_source})")
    
    # 채점 결과
    correction = section.get('correction')
    if correction is not None:
        if correction:
            print(f"⭕ 채점: 정답")
        else:
            print(f"❌ 채점: 오답")
    else:
        print(f"❓ 채점: 답지 없음")
    
    # ResNet 정보
    used_resnet = section.get('used_resnet', False)
    resnet_conf = section.get('resnet_confidence', 0.0)
    resnet_failed = section.get('resnet_failed', False)
    
    if used_resnet:
        if resnet_failed:
            print(f"🤖 ResNet: 실패")
        else:
            print(f"🤖 ResNet: 성공 (신뢰도: {resnet_conf:.4f})")
    else:
        print(f"🤖 ResNet: 사용 안 함")
    
    # YOLO IoU 검증 정보
    yolo_iou = section.get('yolo_iou_verification')
    if yolo_iou:
        print(f"\n🎯 YOLO IoU 검증:")
        print(f"   - ResNet 예측: {yolo_iou['resnet_pred']} (신뢰도: {yolo_iou['resnet_conf']:.4f})")
        print(f"   - YOLO 최고 IoU: {yolo_iou['yolo_best']} (IoU: {yolo_iou['yolo_iou']:.4f})")
        
        # 상위 3개 IoU만 출력
        all_ious = sorted(yolo_iou['all_ious'], key=lambda x: x['iou'], reverse=True)[:3]
        print(f"   - IoU 상위 3개:")
        for result in all_ious:
            print(f"     • {result['number']}: IoU={result['iou']:.4f}, Conf={result['confidence']:.3f}")
    
    # Crop 정보
    crop_success = section.get('crop_success', False)
    if crop_success:
        section_path = section.get('section_crop_path')
        print(f"\n📁 Section 이미지: {section_path}")
    else:
        failure_reason = section.get('crop_failure_reason', 'unknown')
        print(f"\n❌ Crop 실패: {failure_reason}")
    
    # 경계 이슈
    is_boundary = section.get('is_boundary_issue', False)
    if is_boundary:
        print(f"⚠️  경계 근처 문제번호 검출됨")
    
    # 디버그 정보
    debug = section.get('debug_info', {})
    if debug:
        print(f"\n🔍 디버그 정보:")
        print(f"   - 원본 bbox: {debug.get('original_bbox')}")
        print(f"   - 확장 bbox: {debug.get('expanded_bbox')}")
        print(f"   - Crop 크기: {debug.get('crop_size')}")
        print(f"   - answer_1 검출: {debug.get('answer_1_count', 0)}개")
        print(f"   - answer_2 검출: {debug.get('answer_2_count', 0)}개")
        print(f"   - 문제번호 검출: {debug.get('problem_number_count', 0)}개")


def print_summary(result: dict):
    """전체 처리 결과 요약 출력"""
    print(f"\n{'='*60}")
    print(f"처리 결과 요약")
    print(f"{'='*60}")
    
    print(f"📄 페이지: {result['page_name']}")
    print(f"🔢 페이지 번호 (OCR): {result.get('page_number_ocr', 'N/A')}")
    print(f"⏱️  처리 시간: {result['processing_time']:.2f}초")
    print(f"📊 총 Section 수: {result['total_sections']}")
    
    crop_failures = result.get('crop_failure_count', 0)
    if crop_failures > 0:
        print(f"❌ Crop 실패: {crop_failures}개")
    
    # Section별 통계
    sections = result['sections']
    total = len(sections)
    
    with_problem = sum(1 for s in sections if s.get('problem_number_ocr'))
    with_answer = sum(1 for s in sections if s.get('answer_number'))
    used_resnet = sum(1 for s in sections if s.get('used_resnet'))
    resnet_success = sum(1 for s in sections if s.get('used_resnet') and not s.get('resnet_failed'))
    
    # 채점 통계
    correct_count = sum(1 for s in sections if s.get('correction') == True)
    incorrect_count = sum(1 for s in sections if s.get('correction') == False)
    no_correction = sum(1 for s in sections if s.get('correction') is None)
    
    print(f"\n📈 통계:")
    print(f"   - 문제번호 인식: {with_problem}/{total} ({with_problem/total*100:.1f}%)")
    print(f"   - 정답 인식: {with_answer}/{total} ({with_answer/total*100:.1f}%)")
    print(f"   - ResNet 사용: {used_resnet}/{total} ({used_resnet/total*100:.1f}%)")
    if used_resnet > 0:
        print(f"   - ResNet 성공: {resnet_success}/{used_resnet} ({resnet_success/used_resnet*100:.1f}% of used)")
    
    if correct_count + incorrect_count > 0:
        print(f"\n✅ 채점 결과:")
        print(f"   - 정답: {correct_count}개")
        print(f"   - 오답: {incorrect_count}개")
        print(f"   - 정답률: {correct_count/(correct_count+incorrect_count)*100:.1f}%")
        if no_correction > 0:
            print(f"   - 채점 불가: {no_correction}개")
    
    # 답안 출처 통계
    answer_sources = {}
    for s in sections:
        source = s.get('answer_source')
        if source:
            answer_sources[source] = answer_sources.get(source, 0) + 1
    
    if answer_sources:
        print(f"\n📍 답안 출처:")
        for source, count in sorted(answer_sources.items()):
            print(f"   - {source}: {count}개")


def format_simplified_result(result: dict) -> dict:
    """
    결과를 간소화된 JSON 형식으로 변환
    
    형식:
    {
      "image_path": "...",
      "page_number": "...",
      "sections": [
        {
          "problem_number": "...",
          "answer": "...",
          "correction": true/false/null
        },
        ...
      ]
    }
    """
    simplified = {
        "image_path": result['image_path'],
        "page_number": result.get('page_number_ocr'),
        "sections": []
    }
    
    for section in result['sections']:
        simplified_section = {
            "problem_number": section.get('problem_number_ocr'),
            "answer": section.get('answer_number'),
            "correction": section.get('correction')
        }
        simplified['sections'].append(simplified_section)
    
    return simplified


def test_single_image(image_path: str, model_dir_1104: str, model_dir_1004: str,
                      output_dir: str, answer_key_path: str = None,
                      resnet_answer_1_path: str = None,
                      resnet_answer_2_path: str = None,
                      section_padding: int = 50):
    """
    단일 이미지를 HierarchicalCropPipeline으로 처리하고 결과를 검증
    
    Args:
        image_path: 테스트할 이미지 경로
        model_dir_1104: 1104 모델 디렉토리
        model_dir_1004: 1004 모델 디렉토리
        output_dir: 출력 디렉토리
        answer_key_path: 답지 파일 경로 (선택)
        resnet_answer_1_path: answer_1 ResNet 모델 경로 (선택)
        resnet_answer_2_path: answer_2 ResNet 모델 경로 (선택)
        section_padding: Section padding 값 (기본 50px)
    """
    
    # 입력 검증
    if not os.path.exists(image_path):
        logger.error(f"이미지 파일을 찾을 수 없습니다: {image_path}")
        return False
    
    if not os.path.exists(model_dir_1104):
        logger.error(f"1104 모델 디렉토리를 찾을 수 없습니다: {model_dir_1104}")
        return False
    
    if not os.path.exists(model_dir_1004):
        logger.error(f"1004 모델 디렉토리를 찾을 수 없습니다: {model_dir_1004}")
        return False
    
    # 출력 디렉토리 생성
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    # HierarchicalCropPipeline 초기화
    logger.info("HierarchicalCropPipeline 초기화 중...")
    
    # 경로 추가 (services 모듈을 import하기 위해)
    script_dir = Path(__file__).parent
    if str(script_dir) not in sys.path:
        sys.path.insert(0, str(script_dir))
    
    try:
        from services.hierarchical_crop import HierarchicalCropPipeline
    except ImportError as e:
        logger.error(f"HierarchicalCropPipeline import 실패: {e}")
        logger.error("services/hierarchical_crop.py 파일이 있는지 확인하세요.")
        return False
    
    try:
        pipeline = HierarchicalCropPipeline(
            model_dir_1104=model_dir_1104,
            model_dir_1004=model_dir_1004,
            section_padding=section_padding,
            answer_key_path=answer_key_path,
            resnet_answer_1_path=resnet_answer_1_path,
            resnet_answer_2_path=resnet_answer_2_path
        )
        logger.info("✅ 파이프라인 초기화 완료")
    except Exception as e:
        logger.error(f"파이프라인 초기화 실패: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    # 이미지 처리
    logger.info(f"\n{'='*60}")
    logger.info(f"이미지 처리 시작: {image_path}")
    logger.info(f"{'='*60}\n")
    
    try:
        result = pipeline.process_page(image_path, output_path)
        
        if result is None:
            logger.warning("⚠️  페이지가 답지에 없어 처리되지 않았습니다.")
            return True
        
        # 결과 출력
        print_summary(result)
        
        # 각 Section 결과 출력
        for idx, section in enumerate(result['sections']):
            print_section_result(section, idx)
        
        # ✨ 간소화된 JSON 형식으로 저장
        simplified_result = format_simplified_result(result)
        
        json_path = output_path / f"{result['page_name']}_result.json"
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(simplified_result, f, indent=2, ensure_ascii=False)
        
        logger.info(f"\n✅ 간소화된 결과가 저장되었습니다: {json_path}")
        
        # 상세 결과도 별도로 저장 (디버깅용)
        detailed_json_path = output_path / f"{result['page_name']}_detailed.json"
        with open(detailed_json_path, 'w', encoding='utf-8') as f:
            json.dump(result, f, indent=2, ensure_ascii=False)
        
        logger.info(f"✅ 상세 결과가 저장되었습니다: {detailed_json_path}")
        
        # 간소화된 결과 미리보기
        print(f"\n{'='*60}")
        print("간소화된 JSON 결과 미리보기")
        print(f"{'='*60}")
        print(json.dumps(simplified_result, indent=2, ensure_ascii=False))
        
        return True
        
    except Exception as e:
        logger.error(f"❌ 이미지 처리 중 오류 발생: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """메인 함수 - 커맨드라인 인자 파싱"""
    import argparse
    
    # ============================================================
    # 고정 설정값
    # ============================================================
    MODEL_DIR_1104 = "./models/Detection/legacy/Model_routing_1104"
    MODEL_DIR_1004 = "./models/Detection/legacy/Model_routing_1004"
    ANSWER_KEY_PATH = "./test/Hierarchical_crop/answers/yolo_answer.txt"
    RESNET_ANSWER_1_PATH = "./models/Recognition/models/answer_1_resnet.pth"
    RESNET_ANSWER_2_PATH = "./models/Recognition/models/answer_2_resnet.pth"
    SECTION_PADDING = 50
    # ============================================================
    
    parser = argparse.ArgumentParser(
        description='HierarchicalCropPipeline 단일 이미지 테스트',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
예제:
  # 이미지 경로만 지정하면 됩니다
  python test_hierarchical_crop.py --image test.jpg --output ./output
  
  # 또는 더 간단하게
  python test_hierarchical_crop.py --image test.jpg

고정 설정값:
  - 1104 모델: ./models/Detection/legacy/Model_routing_1104
  - 1004 모델: ./models/Detection/legacy/Model_routing_1004
  - 답지: ./DB/answer.txt
  - ResNet answer_1: ./models/Recognition/models/resnet_answer_1.pth
  - ResNet answer_2: ./models/Recognition/models/resnet_answer_2.pth
  - Section padding: 50px

출력 JSON 형식:
  {
    "image_path": "...",
    "page_number": "1",
    "sections": [
      {
        "problem_number": "1",
        "answer": "3",
        "correction": true
      },
      ...
    ]
  }
        """
    )
    
    parser.add_argument('--image', required=True, help='테스트할 이미지 경로')
    parser.add_argument('--output', default='./test_output', help='출력 디렉토리 (기본: ./test_output)')
    
    args = parser.parse_args()
    
    # 고정값 사용 안내
    logger.info("\n" + "="*60)
    logger.info("고정 설정값 사용")
    logger.info("="*60)
    logger.info(f"1104 모델: {MODEL_DIR_1104}")
    logger.info(f"1004 모델: {MODEL_DIR_1004}")
    logger.info(f"답지: {ANSWER_KEY_PATH}")
    logger.info(f"ResNet answer_1: {RESNET_ANSWER_1_PATH}")
    logger.info(f"ResNet answer_2: {RESNET_ANSWER_2_PATH}")
    logger.info(f"Section padding: {SECTION_PADDING}px")
    logger.info("="*60 + "\n")
    
    # 테스트 실행
    success = test_single_image(
        image_path=args.image,
        model_dir_1104=MODEL_DIR_1104,
        model_dir_1004=MODEL_DIR_1004,
        output_dir=args.output,
        answer_key_path=ANSWER_KEY_PATH,
        resnet_answer_1_path=RESNET_ANSWER_1_PATH,
        resnet_answer_2_path=RESNET_ANSWER_2_PATH,
        section_padding=SECTION_PADDING
    )
    
    if success:
        logger.info("\n✅ 테스트 완료!")
        sys.exit(0)
    else:
        logger.error("\n❌ 테스트 실패!")
        sys.exit(1)


if __name__ == "__main__":
    main()

# python test_hierarchical_crop.py --image test.jpg --output ./my_output
# python -m test.Hierarchical_crop.services_hierarchical_crop_test --image "./test/Hierarchical_crop/images/exp_images/학생이 푼 문제(실전 모의고사) - 1.jpg" --output "./test/Hierarchical_crop/images/service_test"