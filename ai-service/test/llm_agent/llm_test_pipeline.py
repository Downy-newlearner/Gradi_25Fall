import os
import csv
import base64
import re
import ast
import unicodedata
import time
from io import BytesIO
from dotenv import load_dotenv
from groq import Groq
from tqdm import tqdm
from PIL import Image
import pandas as pd

# OpenAI와 Gemini 지원을 위한 추가 import
try:
    import openai
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False
    print("⚠️ OpenAI 라이브러리가 설치되지 않음. pip install openai로 설치하세요.")

try:
    import google.generativeai as genai
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False
    print("⚠️ Google Generative AI 라이브러리가 설치되지 않음. pip install google-generativeai로 설치하세요.")

load_dotenv()

# ----------------------
# 이미지 처리
# ----------------------
def resize_image_to_bytes(image_path, max_size=(1024, 1024)):
    try:
        with Image.open(image_path) as img:
            img = img.convert("RGB")
            img.thumbnail(max_size, Image.Resampling.LANCZOS)
            buffer = BytesIO()
            img.save(buffer, format="JPEG")
            buffer.seek(0)
            return buffer.read()
    except Exception as e:
        print(f"⚠️ 이미지 리사이즈 실패: {image_path} ({e})")
        with open(image_path, "rb") as f:
            return f.read()

def encode_image(image_path):
    image_bytes = resize_image_to_bytes(image_path)
    return base64.b64encode(image_bytes).decode("utf-8")

# ----------------------
# 공통 프롬프트
# ----------------------
PROMPT_TEXT = """
*지시*: 다음 이미지는 한국의 수학 문제집 중 한 문제에 대한 이미지입니다. 맥락을 참고하여 이미지 분석 후 정보를 추출하세요.
*맥락*: 문제의 답은 학생 손글씨로 작성되어 있습니다.
    - 문제 유형: 객관식 또는 주관식입니다.
    - 한 문제 내에 꼬리 문제가 존재할 수 있습니다.
    - 답은 한 개 일 수도 있고, 여러 개 일 수도 있습니다.
    
출력 형식은 아래를 참고하며, 이미지에 나타난 손글씨 중 답으로 보이는 부분을 찾아주세요.
*추출할 정보*: 문제 번호, 학생이 작성한(고른) 답
*출력 형식*:
    - 문제 번호: 학생이 작성한(고른) 답 \n\n
    - 문제 번호에는 한 문제에 대한 번호를 작성합니다.
        - 한국의 수학 문제집의 문제 번호는 일반적으로 네 자리 숫자로 구성됩니다.
        - 문제 번호가 한 자리 숫자인 경우
            - ex. 0001
            - 이를 추출할 때 앞의 0을 제거하고 1으로 표기합니다.
        - 문제 번호가 두 자리 숫자인 경우
            - ex. 0010
            - 이를 추출할 때 앞의 0을 제거하고 10으로 표기합니다.
        - 문제 번호가 세 자리 숫자인 경우
            - ex. 0189
            - 이를 추출할 때 앞의 0을 제거하고 189로 표기합니다.
        - 문제 번호가 네 자리 숫자인 경우
            - ex. 1780
            - 이를 추출할 때 네 자리 숫자 그대로 표기합니다.
    - 꼬리 문제가 있는 경우에는 꼬리 문제 번호는 답 부분에 이를 나타냅니다.
*출력 예시*:
    1. 한 문제에 답이 한 개인 경우
        - 1: 15
            - 설명: 1번 문제, 답이 15라는 의미
        - 2: 7^2
            - 설명: 2번 문제, 답이 7^2(7의 제곱)이라는 의미
            
    2. 한 문제에 답이 여러 개인 경우
        - 3: [1, 2, 3]
            - 설명: 3번 문제, 답이 1, 2, 그리고 3이라는 의미
        - 4: [3, 24]
            - 설명: 4번 문제, 답이 3 그리고 24라는 의미
        - 10: [ㄱ, ㄷ]
            - 설명: 10번 문제, 답이 ㄱ 그리고 ㄷ이라는 의미
            
    3. 한 문제에 꼬리 문제(sub question)가 존재하는 경우
        - 5: [1:7, 2:11, 3:[8,9,10,11]]
            - 설명: 5번 문제에 꼬리 문제 1번은 답이 7, 꼬리 문제 2번은 답이 11, 꼬리 문제 3번은 답이 8,9,10, 그리고 11이라는 의미
        - 6: [1:15, 2:10, 3:22]
            - 설명: 6번 문제에 꼬리 문제 1번은 답이 15, 꼬리 문제 2번은 답이 10, 꼬리 문제 3번은 답이 22이라는 의미
        - 7: [a:55, b:13]
            - 설명: 7번 문제에 꼬리 문제 a는 답이 55, 꼬리 문제 b는 답이 13이라는 의미

위 지시, 맥락, 추출 정보, 출력 형식, 출력 예시를 기반으로 다른 설명이나 추가 문장은 쓰지 말고 출력 형식에 맞게 결과만 출력하세요.
"""

# ----------------------
# 각 API별 호출 함수
# ----------------------
def decode_image_groq(model, api_key, image_path):
    """Groq API를 사용한 이미지 디코딩"""
    base64_image = encode_image(image_path)
    client = Groq(api_key=api_key)
    chat_completion = client.chat.completions.create(
        messages=[{
            "role": "user",
            "content": [
                {"type": "text", "text": PROMPT_TEXT},
                {"type": "image_url",
                 "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}}
            ]
        }],
        model=model,
    )
    return chat_completion.choices[0].message.content

def decode_image_openai(model, api_key, image_path):
    """OpenAI API를 사용한 이미지 디코딩"""
    if not OPENAI_AVAILABLE:
        raise ImportError("OpenAI 라이브러리가 설치되지 않았습니다.")
    
    base64_image = encode_image(image_path)
    client = openai.OpenAI(api_key=api_key)
    
    response = client.chat.completions.create(
        model=model,
        messages=[
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": PROMPT_TEXT},
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}
                    }
                ]
            }
        ],
        max_tokens=1000
    )
    return response.choices[0].message.content

def decode_image_gemini(model, api_key, image_path):
    """Gemini API를 사용한 이미지 디코딩"""
    if not GEMINI_AVAILABLE:
        raise ImportError("Google Generative AI 라이브러리가 설치되지 않았습니다.")
    
    genai.configure(api_key=api_key)
    
    # 모델명에서 'models/' 제거 (있는 경우)
    model_name = model.replace('models/', '') if model.startswith('models/') else model
    
    # 이미지 바이트 로드
    image_bytes = resize_image_to_bytes(image_path)
    
    # Gemini 모델 초기화
    model_instance = genai.GenerativeModel(model_name)
    
    # 이미지 객체 생성
    image_part = {
        "mime_type": "image/jpeg",
        "data": image_bytes
    }
    
    # 요청 생성
    response = model_instance.generate_content([PROMPT_TEXT, image_part])
    return response.text

# ----------------------
# 통합 이미지 디코딩 함수
# ----------------------
def decode_image(model, api_key, image_path):
    """모델에 따라 적절한 API를 선택하여 이미지 디코딩"""
    model_lower = model.lower()
    
    if 'llama' in model_lower or 'groq' in model_lower:
        return decode_image_groq(model, api_key, image_path)
    elif 'gpt' in model_lower or 'openai' in model_lower:
        return decode_image_openai(model, api_key, image_path)
    elif 'gemini' in model_lower:
        return decode_image_gemini(model, api_key, image_path)
    else:
        # 기본적으로 Groq API 사용
        print(f"⚠️ 모델 '{model}'의 API 타입을 자동 감지할 수 없음. Groq API를 사용합니다.")
        return decode_image_groq(model, api_key, image_path)

def safe_decode_image(model, api_key, image_path, retries=3, wait_sec=5):
    """안전한 이미지 디코딩 (재시도 로직 포함)"""
    for attempt in range(retries):
        try:
            return decode_image(model, api_key, image_path)
        except Exception as e:
            err_str = str(e)
            
            # 공통 에러 처리
            if any(error in err_str for error in ["InternalServerError", "500", "internal_error"]):
                print(f"⚠️ 내부 서버 오류: {image_path} ({attempt+1}/{retries}) 대기 {wait_sec}s")
                time.sleep(wait_sec)
            elif any(error in err_str for error in ["RateLimitError", "429", "rate_limit", "quota"]):
                wait_time = wait_sec * (10 if "openai" in model.lower() else 5)
                print(f"⚠️ 속도 제한 오류: {image_path} ({attempt+1}/{retries}) 대기 {wait_time}s")
                time.sleep(wait_time)
            elif "ImportError" in err_str:
                print(f"⚠️ 라이브러리 오류: {e}")
                break
            else:
                print(f"⚠️ 기타 오류 발생: {image_path} ({e})")
                if attempt < retries - 1:
                    time.sleep(wait_sec)
                else:
                    break
    return None

# ----------------------
# 응답 파싱 (기존과 동일)
# ----------------------
def response_split(response):
    # None, NaN 등 처리
    if response is None:
        return None, None

    # 문자열 아닌 경우 문자열로 변환
    if not isinstance(response, str):
        response = str(response)

    response = response.strip()
    if not response:
        return None, None

    # 여러 줄 처리
    lines = [line.strip() for line in response.splitlines() if line.strip()]
    parsed_answers = {}
    q_num_main = None

    for line in lines:
        # 앞 공백 제거 후 매칭
        match = re.match(r"^-?(\d+)\s*:\s*(.+)$", line)
        if match:
            q_num = int(match.group(1))
            ans = match.group(2).strip()

            # 한글이 포함되고 ','가 있으면 리스트로 분리
            if re.search(r"[ㄱ-ㅎ가-힣]", ans) and "," in ans:
                ans_list = [a.strip(" ()") for a in ans.split(",") if a.strip()]
                parsed_answers[q_num] = ans_list
            else:
                parsed_answers[q_num] = ans

    if len(parsed_answers) == 1:
        q_num_main, answer = list(parsed_answers.items())[0]
        return q_num_main, answer

    return None, parsed_answers if parsed_answers else None

# ----------------------
# Annotation 파싱 (기존과 동일)
# ----------------------
def split_top_level_commas(s):
    parts = []
    current = ''
    level = 0
    for c in s:
        if c == '[':
            level += 1; current += c
        elif c == ']':
            level -= 1; current += c
        elif c == ',' and level == 0:
            parts.append(current.strip())
            current = ''
        else:
            current += c
    if current: parts.append(current.strip())
    return parts

def parse_problem_info(input_str):
    top_level_parts = split_top_level_commas(input_str)
    if len(top_level_parts) < 4:
        raise ValueError(f"형식 오류: {input_str}")

    file_part = top_level_parts[0]
    problem_number = int(top_level_parts[1])
    type_str = top_level_parts[2]
    answer_str = ','.join(top_level_parts[3:])

    file_match = re.match(r"(.+?) - (\d+)_section_(\d+)_conf[\d.]+\.jpg", file_part)
    if not file_match:
        raise ValueError(f"파일명 형식 오류: {file_part}")

    book = file_match.group(1)
    page = int(file_match.group(2))
    section_number = int(file_match.group(3))

    return {"file": file_part, "book": book, "page": page,
            "section_number": section_number, "problem_number": problem_number,
            "type": type_str, "answer": answer_str}

def load_annotation_dict(annotation_file):
    mapping = {}
    with open(annotation_file, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line: continue
            parts = [p.strip() for p in line.split(',', 3)]
            if len(parts) < 4 or not parts[1].isdigit(): continue
            info = parse_problem_info(line)
            mapping[os.path.basename(info["file"])] = info
    return mapping

def clean_string(s):
    s = unicodedata.normalize("NFC", s)
    s = re.sub(r"\s+", "", s)
    s = re.sub(r"[\u200b\u200c\u200d\uFEFF]", "", s)
    return s.lower()

# ----------------------
# 채점
# ----------------------

char_to_num = {
    "①": "1",
    "②": "2",
    "③": "3",
    "④": "4",
    "⑤": "5",
}

symbol_map = {
    "×": "*",
    "²": "^2",
    "⁶": "^6",
}

def parse_value(val):
    """단일 값, 리스트, 튜플, 딕셔너리 표준화"""
    if val is None:
        return None
    if isinstance(val, float) and np.isnan(val):
        return None
    if isinstance(val, (pd.Series, np.ndarray, list, tuple)):
        return [parse_value(v) for v in val]

    val = str(val).strip()

    # 기호 변환
    for k, v in char_to_num.items():
        val = val.replace(k, v)
    for k, v in symbol_map.items():
        val = val.replace(k, v)

    # '개', " 제거
    val = val.replace("개", "").replace('"', "")

    # 괄호 처리
    paren_match = re.findall(r"\((.*?)\)", val)
    val_outside = re.sub(r"\(.*?\)", "", val).strip()

    if paren_match:
        # 괄호 안 값만 숫자/문자 추출
        inner_vals = [p.strip() for p in paren_match]
        # 괄호 밖 값도 숫자만 같다면 무시
        if all(v.isdigit() for v in inner_vals) and val_outside.isdigit() and int(val_outside) == int(inner_vals[0]):
            return int(inner_vals[0])
        # 단일 괄호
        if len(inner_vals) == 1:
            return parse_value(inner_vals[0])
        return [parse_value(p) for p in inner_vals]
    elif val_outside:
        val = val_outside

    # 딕셔너리 패턴: {a:1, b:2}
    dict_match = re.match(r"^\{.*:.*\}$", val)
    if dict_match:
        try:
            dict_items = re.findall(r"(\S+?)\s*:\s*(\S+)", val)
            return {k: parse_value(v) for k, v in dict_items}
        except:
            pass

    # 리스트 패턴: [a,b,c]
    list_match = re.findall(r"\[([^\[\]]+)\]", val)
    if list_match:
        items = list_match[0].split(",")
        return [parse_value(i.strip()) for i in items]

    # 콤마 구분
    if "," in val:
        items = val.split(",")
        return [parse_value(i.strip()) for i in items]

    # 숫자 변환
    if val.isdigit():
        return int(val)

    return val

def compare_answer(pred, gold):
    try:
        val1 = parse_value(pred)
        val2 = parse_value(gold)
        return val1 == val2
    except:
        return False
    
# ----------------------
# Annotation 처리 (기존과 동일)
# ----------------------
def process_annotations(base_dir, annotation_dict, source_name, model, api_key):
    results = []
    jpg_files = [f for f in os.listdir(base_dir) if f.lower().endswith(".jpg")]

    for fname in tqdm(jpg_files, desc=f"Processing {source_name} ({model})"):
        fname_clean = clean_string(fname)
        matched = None
        for key, info in annotation_dict.items():
            file_clean = clean_string(info.get("file", ""))
            if file_clean == fname_clean:
                matched = info
                break
        if not matched:
            print(f"⚠️ 매칭 실패: {fname}")
            continue

        image_path = os.path.join(base_dir, fname)
        response = safe_decode_image(model, api_key, image_path)
        if response is None:
            print(f"⚠️ 처리 실패: {fname}")
            continue

        q_num, pred_answer = response_split(response)
        correct = compare_answer(pred_answer, matched["answer"])

        results.append({
            "source": source_name,
            "model": model,
            "book": matched["book"],
            "page": matched["page"],
            "problem_number": matched["problem_number"],
            "type": matched["type"],
            "answer": matched["answer"],
            "response": response,
            "pred_q_num": q_num,
            "pred_answer": pred_answer,
            "correct": correct
        })
    return results


# ----------------------
# 메인 실행
# ----------------------
if __name__ == "__main__":
    ann1 = load_annotation_dict("test/images/LLM_annotation/annotation.txt")
    ann2 = load_annotation_dict("test/images/LLM_annotation_wrong/annotation_wrong_answer.txt")

    # 모델과 API 키 설정
    models = {
        "meta-llama/llama-4-scout-17b-16e-instruct": os.environ.get("GROQ_API_KEY"),
        "gpt-4o": os.environ.get("OPENAI_API_KEY"),
        "gemini-2.0-flash-exp": os.environ.get("GEMINI_API_KEY")  # models/ 제거
    }

    # 사용 가능한 모델만 필터링
    available_models = {}
    for model_name, api_key in models.items():
        if api_key:
            available_models[model_name] = api_key
        else:
            print(f"⚠️ {model_name}의 API 키가 설정되지 않음")

    data_sources = [
        ("test/images/LLM_annotation", ann1, "LLM_annotation"),
        ("test/images/LLM_annotation_wrong", ann2, "LLM_annotation_wrong")
    ]

    # 각 모델에 대해 처리
    for model_name, api_key in available_models.items():
        print(f"\n🚀 {model_name} 모델 처리 시작...")
        model_results = []
        
        for folder, ann_dict, source_name in data_sources:
            print(f"📁 처리 중: {source_name}")
            try:
                model_results.extend(process_annotations(folder, ann_dict, source_name, model_name, api_key))
            except Exception as e:
                print(f"⚠️ {source_name} 처리 중 오류: {e}")
                continue

        # 결과 저장
        if model_results:
            safe_model_name = re.sub(r"[^a-zA-Z0-9_-]", "_", model_name)
            output_path = f"./test/llm_agent/results/results_{safe_model_name}.csv"
            
            # 결과 디렉토리 생성
            os.makedirs(os.path.dirname(output_path), exist_ok=True)

            with open(output_path, "w", newline="", encoding="utf-8") as csvfile:
                writer = csv.DictWriter(csvfile, fieldnames=[
                    "source", "model", "book", "page", "problem_number", "type",
                    "answer", "response", "pred_q_num", "pred_answer", "correct"
                ])
                writer.writeheader()
                writer.writerows(model_results)

            # 간단한 통계 출력
            total = len(model_results)
            correct = sum(1 for r in model_results if r["correct"])
            accuracy = (correct / total * 100) if total > 0 else 0
            
            print(f"✅ {output_path} 저장 완료")
            print(f"📊 {model_name} 결과: {correct}/{total} (정확도: {accuracy:.2f}%)")
        else:
            print(f"⚠️ {model_name}에 대한 결과가 없습니다.")

    print("\n🎉 모든 모델 처리 완료!")