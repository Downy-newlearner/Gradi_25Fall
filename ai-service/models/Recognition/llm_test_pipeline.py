import os
import csv
import base64
import re
import ast
import unicodedata
from dotenv import load_dotenv
from groq import Groq
from tqdm import tqdm

load_dotenv()


def encode_image(image_path):
    """이미지를 base64로 인코딩"""
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode('utf-8')

def decode_image(model, api_key, image_path):
    """
    이미지의 문제 번호와 답안을 추출
    """
    base64_image = encode_image(image_path)
    client = Groq(api_key=api_key)
    chat_completion = client.chat.completions.create(
        messages=[
            {
                "role": "user",
                "content": [ 
                    {
                        "type": "text",
                        "text": """
                        *지시*: 다음 이미지는 한국 수학 문제집의 한 문제에 대한 이미지야. 맥락을 참고하여 이미지를 분석 후 정보를 추출해줘.

                        *맥락*: 문제는 프린트로 인쇄되어있고, 답은 손글씨로 작성돼있어. 너는 학생이 작성한 답안을 인식하여 추출하는 것이 목표야. 
                            - 절대 문제를 풀지마.
                            - 학생이 작성한 답안을 추출해.
                            - 하려고 하는 작업이 채점 작업이므로, 틀리게 푼 문제라도 그대로 답안을 추출해.
                            - **학생의 답안을 추출하는게 목표야. 어떻게 작성되어있는지 추출하고 문제를 절대 풀지 마.**
                            
                        *출력 형식*:
                            - 문제 번호: 답
                            - 꼬리 문제가 있는 경우에는 답 부분에 이를 나타낸다.
                        
                        *출력 예시*
                            - 1: 15
                            - 2: 7^2
                            - 3: [1, 2, 3]
                            - 5: [1:7, 2:11, 3:[8,9,10,11]]
                        """
                    },
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/png;base64,{base64_image}",
                        },
                    },
                ],
            }
        ],
        model=model,
    )

    return chat_completion.choices[0].message.content

def response_split(response):
    """
    응답 후처리
    """
    if response.startswith("-"):
      response = response[1:].strip()
    
    if ":" in response:
        q_num, answer = response.split(": ", 1)
        return q_num.strip(), answer.strip()
    
    return None, None

def split_top_level_commas(s):
    """
    대괄호 레벨을 고려해서 top-level 쉼표 기준으로 분리
    """
    parts = []
    current = ''
    level = 0
    for c in s:
        if c == '[':
            level += 1
            current += c
        elif c == ']':
            level -= 1
            current += c
        elif c == ',' and level == 0:
            parts.append(current.strip())
            current = ''
        else:
            current += c
    if current:
        parts.append(current.strip())
    return parts

def parse_problem_info(input_str):
    """
    annotation.txt 한 줄 파싱
    """
    # 파일명 부분과 나머지 분리
    top_level_parts = split_top_level_commas(input_str)
    if len(top_level_parts) < 4:
        raise ValueError(f"형식 오류: {input_str}")

    file_part = top_level_parts[0]
    problem_number = int(top_level_parts[1])
    type_str = top_level_parts[2]
    answer_str = ','.join(top_level_parts[3:])  # 나머지는 answer로 합침

    # 파일명 파싱
    file_match = re.match(r"(.+?) - (\d+)_section_(\d+)_conf[\d.]+\.jpg", file_part)
    if not file_match:
        raise ValueError(f"파일명 형식 오류: {file_part}")

    book = file_match.group(1)
    page = int(file_match.group(2))
    section_number = int(file_match.group(3))

    # type과 answer 변환
    def parse_sub_question(s):
        s = s.strip()
        if s.startswith('[') and s.endswith(']'):
            s_inner = s[1:-1]
            items = split_top_level_commas(s_inner)
            result = {}
            for item in items:
                if ':' in item:
                    key, value = item.split(':', 1)
                    key, value = key.strip(), value.strip()
                    if value.startswith('[') and value.endswith(']'):
                        value = ast.literal_eval(value)
                    else:
                        try:
                            value = int(value)
                        except:
                            pass
                    result[key] = value
                else:
                    try:
                        return ast.literal_eval("[" + s_inner + "]")
                    except:
                        return s_inner
            return result
        else:
            return s

    return {
        "file": file_part,
        "book": book,
        "page": page,
        "section_number": section_number,
        "problem_number": problem_number,
        "type": type_str,
        "answer": answer_str
    }

def compare_answer(pred, gold):
    """모델 응답과 실제 정답 비교"""
    try:
        return str(pred).strip() == str(gold).strip()
    except:
        return False

def load_annotation_dict(annotation_file):
    """annotation.txt 파일을 {파일명: info} dict로 변환"""
    mapping = {}
    with open(annotation_file, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = [p.strip() for p in line.split(',', 3)]
            if len(parts) < 4 or not parts[1].isdigit():
                continue
            info = parse_problem_info(line)
            mapping[os.path.basename(info["file"])] = info
    return mapping

def clean_string(s):
    """문자열 정제: Unicode 정규화, 공백 제거, invisible char 제거, 소문자 변환"""
    s = unicodedata.normalize("NFC", s)
    s = re.sub(r"\s+", "", s)  # 공백 제거
    s = re.sub(r"[\u200b\u200c\u200d\uFEFF]", "", s)  # invisible char 제거
    return s.lower()

def process_annotations(base_dir, annotation_dict, source_name, model="meta-llama/llama-4-scout-17b-16e-instruct", api_key=os.environ.get("GROQ_API_KEY")):
    results = []
    jpg_files = [f for f in os.listdir(base_dir) if f.lower().endswith(".jpg")]

    # tqdm로 progress bar 감싸기
    for fname in tqdm(jpg_files, desc=f"Processing {source_name}"):
        fname_clean = clean_string(fname)

        matched = None
        for key, info in annotation_dict.items():
            file_value = info.get("file", "")
            file_clean = clean_string(file_value)
            if file_clean == fname_clean:
                matched = info
                break

        if not matched:
            print(f"⚠️ 매칭 실패: {fname} (annotation에 file이 없음)")
            continue

        image_path = os.path.join(base_dir, fname)

        response = decode_image(model, api_key, image_path)
        correct = compare_answer(response, info["answer"])

        results.append({
            "source": source_name,
            "book": info["book"],
            "page": info["page"],
            "problem_number": info["problem_number"],
            "type": info["type"],
            "answer": info["answer"],
            "response": response,
            "correct": correct
        })
    return results

if __name__ == "__main__":
    results = []

    # annotation 파일 로드
    ann1 = load_annotation_dict("images/LLM_annotation/annotation.txt")
    ann2 = load_annotation_dict("images/LLM_annotation_wrong/annotation_wrong_answer.txt")

    # 폴더별 처리
    results.extend(process_annotations("images/LLM_annotation", ann1, "LLM_annotation"))
    results.extend(process_annotations("images/LLM_annotation_wrong", ann2, "LLM_annotation_wrong"))

    # CSV 저장
    with open("results.csv", "w", newline="", encoding="utf-8") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=[
            "source", "book", "page", "problem_number", "type", "answer", "response", "correct"
        ])
        writer.writeheader()
        writer.writerows(results)

    print("✅ results.csv 저장 완료")
