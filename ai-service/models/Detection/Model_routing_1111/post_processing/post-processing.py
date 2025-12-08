# post-processing.py
# 공백 여부 판단 기준 (복합적):
# 1. 평균 픽셀 값이 240 이상이면 공백 가능성 ↑
# 2. 표준편차(standard deviation)가 낮으면(예: 15 이하), 매우 균일한 색상 → 공백 가능성 ↑
# 3. 엣지(Edge) 검출(예: Canny 등) 결과 엣지 픽셀 비율이 일정 이하(예: 0.5% 미만)면 텍스트/내용 없음 → 공백 가능성 ↑
# 4. ROI가 이미지 경계를 넘어갈 땐, ROI를 이미지 크기 내로 clip하여 처리 (최대 min, 최소 max로)
# 위 기준을 종합적으로 적용하여 해당 영역이 '공백'인지 판단


# 공백 여부 판단 함수
def is_blank_region(image, roi, mean_thresh=240, stddev_thresh=15, edge_ratio_thresh=0.005):
    """
    이미지에서 roi 영역이 '공백'인지 판단하는 함수.
    - image: numpy array (H, W, 3)
    - roi: (x_min, y_min, x_max, y_max)
    - mean_thresh: 평균 픽셀 임계값 (default 240)
    - stddev_thresh: 표준편차 임계값 (default 15)
    - edge_ratio_thresh: 엣지 비율 임계값 (default 0.005 == 0.5%)
    """
    import numpy as np
    import cv2

    x_min, y_min, x_max, y_max = roi

    # ROI를 이미지 크기 내로 clip
    h, w = image.shape[:2]
    x_min = max(0, int(round(x_min)))
    y_min = max(0, int(round(y_min)))
    x_max = min(w, int(round(x_max)))
    y_max = min(h, int(round(y_max)))

    if x_max <= x_min or y_max <= y_min:
        return True  # 잘못된 ROI는 공백으로 간주

    roi_img = image[y_min:y_max, x_min:x_max]

    # Gray 변환
    if len(roi_img.shape) == 3:
        roi_gray = cv2.cvtColor(roi_img, cv2.COLOR_BGR2GRAY)
    else:
        roi_gray = roi_img

    mean = np.mean(roi_gray)
    stddev = np.std(roi_gray)

    # Canny Edge
    # 자동 임계값 설정(기본값 제공)
    v = np.median(roi_gray)
    lower = int(max(0, 0.66 * v))
    upper = int(min(255, 1.33 * v))
    edges = cv2.Canny(roi_gray, lower, upper)
    edge_ratio = np.sum(edges > 0) / (roi_gray.shape[0]*roi_gray.shape[1]+1e-5)

    # 공백 판정
    result = (mean >= mean_thresh and stddev <= stddev_thresh and edge_ratio <= edge_ratio_thresh)
    return result



# 함수 정의
    # 함수 이름: post_processing
    # 함수 description: yolov8 추론 결과를 후처리하는 함수
    # 입력: yolov8 추론 결과 (json 파일)
    # 출력: 처리된 yolov8 추론 결과 (json 파일)

def post_processing(yolo_json_path, image_path, output_json_path):
    import json
    import cv2
    import numpy as np

    ROI_HEIGHT = 60

    # yolov8 결과 불러오기
    with open(yolo_json_path, "r", encoding="utf-8") as f:
        yolo_result = json.load(f)
    image = cv2.imread(image_path)
    
    if image is None:
        raise ValueError(f"이미지를 로드할 수 없습니다: {image_path}")

    # detections 배열 가져오기
    detections = yolo_result.get('detections', yolo_result) if isinstance(yolo_result, dict) else yolo_result

    # 우선 모든 problem_number의 왼쪽 위 좌표를 찾아 배열에 저장한다. (x_min, y_min)
    question_numbers = []
    for obj in detections:
        class_name = obj.get('class_name', obj.get('label', ''))
        if class_name == 'problem_number':
            question_numbers.append((obj['bbox'][0], obj['bbox'][1]))

    print(f"question_numbers: {question_numbers}\n")
    
    # 반복문: 모든 section에 대해 반복한다.
    # 각 section을 처리하고, 교정이 끝나면 원래 section(obj)를 detections에서 즉시 삭제
    sections_to_remove = []
    for obj in detections[:]:
        class_name = obj.get('class_name', obj.get('label', ''))
        if class_name != 'section':
            continue
        
        import copy
        original_section = obj
        # original_section을 deep copy한 section 생성
        section = copy.deepcopy(obj)

        # INSERT_YOUR_CODE
        original_section['class_name'] = "original_section"


        x_min, y_min = section['bbox'][0], section['bbox'][1]
        x_max, y_max = section['bbox'][2], section['bbox'][3]
    
        # 1. section에 대해 가장 가까운 question_number를 찾아 왼쪽 위 꼭짓점을 맞춘다.
            # - section 객체의 왼쪽 위 좌표를 찾는다. (x_min, y_min)
            # - 해당 좌표와 모든 question_number의 왼쪽 위 좌표와의 거리를 계산하여 가장 작은 거리를 가진 question_number를 찾는다.
            # - section의 왼쪽 위 꼭짓점을 해당 question_number의 왼쪽 위 꼭짓점으로 맞춘다.
            # - 모든 section에 대해 반복한다.
        min_dist = float('inf')
        nearest_qn = None
        for qn_x, qn_y in question_numbers:
            dist = np.sqrt((qn_x - x_min)**2 + (qn_y - y_min)**2)
            if dist < min_dist:
                min_dist = dist
                nearest_qn = (qn_x, qn_y)
        if nearest_qn is not None:
            print(f"\n\n현재 x_min, y_min: {x_min, y_min}, 가장 가까운 question_number: {nearest_qn}")
            x_min = nearest_qn[0]
            y_min = nearest_qn[1]
            section['bbox'][0] = max(0, x_min - 20) # 조절값
            section['bbox'][1] = y_min
            print(f"question_number에 맞게 변경 후 x_min, y_min: {x_min, y_min}\n")


        # 2. section에 대해 Top_line_ROI와 Bottom_line_ROI를 통한 영역 추출 후 공백 여부를 판단한다.
            # 탑라인에서 위가 공백이면 멈추고, 공백이 아니면 올라간다.
            # 바텀라인에서 아래가 공백이면 멈추고, 공백이 아니면 내려간다.

        # 위쪽 확장 (iteration 및 max_iterations 없음)
        print("위쪽 확장시작!!!!!\n\n")
        while True:
            if y_min - ROI_HEIGHT/2 < 0:
                break

            top_upside_roi = [x_min, y_min - ROI_HEIGHT/2, x_max, y_min]
            top_downside_roi = [x_min, y_min, x_max, y_min + ROI_HEIGHT/2]
            top_upside_roi = [max(0, top_upside_roi[0]), max(0, top_upside_roi[1]), min(image.shape[1], top_upside_roi[2]), min(image.shape[0], top_upside_roi[3])]
            top_downside_roi = [max(0, top_downside_roi[0]), max(0, top_downside_roi[1]), min(image.shape[1], top_downside_roi[2]), min(image.shape[0], top_downside_roi[3])]
            is_top_upside_blank = is_blank_region(image, top_upside_roi)
            is_top_downside_blank = is_blank_region(image, top_downside_roi)
            print(f"is_top_upside_blank: {is_top_upside_blank}, is_top_downside_blank: {is_top_downside_blank}\n")
            if not is_top_upside_blank:
                print(f"올라간다. y_min: {y_min} -> {y_min - ROI_HEIGHT/2}\n")
                y_min -= ROI_HEIGHT/2
                section['bbox'][1] = y_min
                continue
            if is_top_upside_blank:
                break
            else:
                break

        # 아래쪽 확장 (iteration 및 max_iterations 없음)
        while True:
            if y_max + ROI_HEIGHT/2 > image.shape[0]:
                break
            bottom_upside_roi = [x_min, y_max-ROI_HEIGHT/2, x_max, y_max]
            bottom_downside_roi = [x_min, y_max, x_max, y_max + ROI_HEIGHT/2]
            bottom_upside_roi = [max(0, bottom_upside_roi[0]), max(0, bottom_upside_roi[1]), min(image.shape[1], bottom_upside_roi[2]), min(image.shape[0], bottom_upside_roi[3])]
            bottom_downside_roi = [max(0, bottom_downside_roi[0]), max(0, bottom_downside_roi[1]), min(image.shape[1], bottom_downside_roi[2]), min(image.shape[0], bottom_downside_roi[3])]
            is_bottom_upside_blank = is_blank_region(image, bottom_upside_roi)
            is_bottom_downside_blank = is_blank_region(image, bottom_downside_roi)

            # 아래쪽 확장 조건: bottom ROI(upside, downside) 영역이 모두 공백이 아니라면 해당 section의 y_max += ROI_HEIGHT/2를 한다.(bbox를 아래로 늘린다.)
            if not is_bottom_downside_blank:
                print("내려갑니다. y_max: ", y_max)
                y_max += ROI_HEIGHT/2
                section['bbox'][3] = y_max
                print("내려간 후 y_max: ", y_max)
                continue
            if is_bottom_downside_blank:
                break
            else:
                break

        # # 교정이 끝난 section을 복사본으로 만들어서 detections에 추가
        # corrected_section = {
        #     'class_name': section.get('class_name', section.get('label', 'section')),
        #     'class_id': section.get('class_id', 0),
        #     'confidence': section.get('confidence', 0.0),
        #     'bbox': [x_min, y_min, x_max, y_max]  # 교정된 bbox
        # }
        # # 다른 필드가 있다면 복사
        # for key in section.keys():
        #     if key not in corrected_section:
        #         corrected_section[key] = section[key]
        
        detections.append(section)
        

    
    # 결과 저장
    if isinstance(yolo_result, dict):
        # 원본 구조 유지
        yolo_result['detections'] = detections
        output_data = yolo_result
    else:
        output_data = detections
    
    with open(output_json_path, "w", encoding="utf-8") as f:
        json.dump(output_data, f, ensure_ascii=False, indent=4)


def visualize_detections(image_path, json_path, output_image_path):
    """
    JSON 파일의 detection 결과를 이미지에 시각화합니다.
    """
    import json
    import cv2
    import numpy as np
    
    # 이미지 로드 (복사본 사용)
    image = cv2.imread(image_path)
    if image is None:
        raise ValueError(f"이미지를 로드할 수 없습니다: {image_path}")
    image = image.copy()  # 원본 이미지 보호를 위해 복사
    
    # JSON 로드
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    detections = data.get('detections', data) if isinstance(data, dict) else data
    
    # 클래스별 색상 정의 (BGR 형식)
    colors = {
        # 큰 객체 클래스
        'section': (0, 255, 0),  # 녹색 (교정된 section, 더 눈에 띄는 색)
        'original_section': (0, 0, 255),  # 진한 빨간색 (original_section은 매우 눈에 띄게 표시)
        'answer_option': (0, 255, 255),  # 노란색 (BGR: 0,255,255 = RGB: 255,255,0)
        'english_content': (255, 0, 0),  # 빨간색
        'korean_content': (255, 0, 255),  # 마젠타
        
        # 작은 객체 클래스
        'problem_number': (255, 255, 0),  # 시안 (BGR: 255,255,0 = RGB: 0,255,255)
        'page_number': (128, 0, 128),  # 보라
        'answer_1': (255, 165, 0),  # 오렌지
        'answer_2': (0, 128, 255),  # 주황색 계열
        
        # 숫자 클래스
        '1': (255, 200, 0),  # 노란색 계열
        '2': (200, 255, 0),  # 연두색 계열
        '3': (0, 255, 200),  # 청록색 계열
        '4': (0, 200, 255),  # 하늘색 계열
        '5': (200, 0, 255),  # 자주색 계열
    }
    
    # 각 detection 그리기
    for obj in detections:
        class_name = obj.get('class_name', obj.get('label', 'unknown'))
        bbox = obj['bbox']
        confidence = obj.get('confidence', 0.0)
        
        x_min, y_min, x_max, y_max = map(int, bbox)
        
        # 색상 선택
        color = colors.get(class_name, (255, 255, 255))  # 기본값: 검정색
        
        # 박스 그리기
        cv2.rectangle(image, (x_min, y_min), (x_max, y_max), color, 2)
        
        # 레이블 텍스트
        label_text = f"{class_name}: {confidence:.2f}"
        (text_width, text_height), baseline = cv2.getTextSize(
            label_text, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 1
        )
        
        # 텍스트 배경
        cv2.rectangle(
            image,
            (x_min, y_min - text_height - baseline - 5),
            (x_min + text_width, y_min),
            color,
            -1
        )
        
        # 텍스트
        cv2.putText(
            image,
            label_text,
            (x_min, y_min - baseline - 2),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.5,
            (0, 0, 0),
            1
        )
    
    # 결과 저장
    cv2.imwrite(output_image_path, image)
    print(f"시각화 결과 저장: {output_image_path}")


def main():
    """
    post_processing 함수를 테스트합니다.
    annotations 폴더의 모든 JSON 파일을 처리합니다.
    """
    from pathlib import Path
    
    # 경로 설정
    base_dir = Path(__file__).parent
    annotations_dir = base_dir / "annotations"
    images_dir = base_dir / "images"
    output_json_dir = base_dir / "test_v15"
    output_viz_dir = base_dir / "visualization_v15"
    
    # 출력 디렉토리 생성
    output_json_dir.mkdir(exist_ok=True)
    output_viz_dir.mkdir(exist_ok=True)
    
    # JSON 파일 목록 가져오기
    json_files = sorted(annotations_dir.glob("*.json"))
    
    if len(json_files) == 0:
        print(f"❌ JSON 파일이 없습니다: {annotations_dir}")
        return
    
    print("=" * 80)
    print("post_processing 함수 테스트")
    print("=" * 80)
    print(f"처리할 파일 수: {len(json_files)}")
    print()
    
    success_count = 0
    error_count = 0
    
    for json_file in json_files:
        try:
            # 이미지 파일 찾기 (JSON 파일명에서 "result_" 접두사 제거)
            json_stem = json_file.stem
            if json_stem.startswith("result_"):
                image_stem = json_stem[7:]  # "result_" 제거 (7글자)
            else:
                image_stem = json_stem
            image_name = image_stem + ".jpg"
            image_path = images_dir / image_name
            
            if not image_path.exists():
                print(f"⚠️  이미지 파일을 찾을 수 없습니다: {image_name}")
                error_count += 1
                continue
            
            # 출력 파일 경로
            output_json_path = output_json_dir / json_file.name
            output_image_path = output_viz_dir / image_name
            
            print(f"📄 처리 중: {json_file.name}")
            
            # 후처리 실행
            post_processing(
                str(json_file),
                str(image_path),
                str(output_json_path)
            )
            
            # 시각화
            visualize_detections(
                str(image_path),
                str(output_json_path),
                str(output_image_path)
            )
            
            print(f"   ✅ 완료: {json_file.name}")
            success_count += 1
            
        except Exception as e:
            print(f"   ❌ 오류 발생: {json_file.name}")
            print(f"      {str(e)}")
            error_count += 1
    
    print()
    print("=" * 80)
    print(f"테스트 완료: 성공 {success_count}개, 실패 {error_count}개")
    print(f"결과 JSON: {output_json_dir}")
    print(f"시각화 이미지: {output_viz_dir}")
    print("=" * 80)


if __name__ == "__main__":
    main()

