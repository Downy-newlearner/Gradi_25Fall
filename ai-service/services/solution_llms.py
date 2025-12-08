# services/solution_llms.py
"""
LLM 기반 수능 영어 문제 해설 생성

- 지문 분석
- 정답과 학생 답안 비교
- 오답인 경우 상세 해설 생성

이 파일은 services/llm_explanation.py에 배치하세요.
"""

import json
import re
import glob
import os
from typing import Optional
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

client = OpenAI(
    api_key=os.getenv('UPSTAGE_API_KEY'),
    base_url="https://api.upstage.ai/v1"
)

# 시스템 프롬프트
SYSTEM_PROMPT = """
당신은 20년 경력의 한국 수능 영어 해설 전문가입니다. 
아래 규칙을 준주하여 학생 답안에 대한 해설을 작성하십시오.

[기본 규칙]
1) 정답(answer)과 학생 답안(user_answer)을 먼저 비교한다.
2) 학생 답안이 정답이면 해설은 제공하지 않는다.
3) 학생 답안이 틀릴 경우:
   - 반드시 해설을 제공한다.
   - 먼저 문제 문항(korean_content)을 읽어, 문제의 요구 사항을 파악한다.
   - 이후 지문(script 또는 english_content)의 내용을 근거로 하여 해설을 작성한다.
   - 외부 지식은 사용하지 않으며, 지문과 문제에만 근거한다.
4) 해설은 반드시 한국어로 작성하며,
   - 상세 해설은 8~10문장 분량으로 작성한다.
   - 해설 요약은 3~4문장 분량으로 작성한다.

[문제 영역]
문제는 다음 두 영역 중 하나에 속합니다:

1) 맥락(context) 영역:
   - 문법 문제를 제외한 유형
   - 해설은 다음 순서를 따른다:
      1) 지문의 핵심 흐름과 주장·내용을 3문장 이내로 요약
      2) 문제 문항이 무엇을 묻는지 설명
      3) 지문을 근거로 학생 답안이 왜 틀렸는지 의미적·논리적으로 설명
      
2) 문법(grammar) 영역:
   - 문법, 어법, 구문 문제
   - 해설은 다음 순서를 따른다:
      1) 문제 문항이 요구하는 문법 요소를 파악
      2) 해당 문법 요소의 규칙을 간단히 설명
      3) 지문을 근거로 학생 답안이 왜 틀렸는지 문법적으로 설명
   

출력 형식은 아래 형식을 유지하십시오.
[출력 형식]:
------------------------------------
## 문제 {problem_number} (p.{page_number})
## 정답: {answer}  
## 사용자의 선택: {user_answer}

## 상세 해설
- (학생 답안이 오답일 경우) 8~10문장의 상세한 한국어 해설

## 해설 요약
- 3~4문장으로 간결하게 요약
------------------------------------
"""

# 유저 프롬프트
USER_PROMPT_TEMPLATE = """
아래는 문제 JSON 배열입니다. 각 JSON 객체에는 다음 필드를 포함할 수 있습니다:
page_number, problem_number, korean_content, english_content, script, answer_option, answer, user_answer

각 문제는 다음 기준에 따라 처리하십시오:

1) 정답(answer)과 학생 답안(user_answer)을 비교합니다.
2) 학생 답안이 정답일 경우:
   - 정답과 학생 답안만 출력하며, 해설은 제공하지 않습니다.
3) 학생 답안이 틀릴 경우:
   - 반드시 한국어 해설을 제공합니다.
   - 해설 작성 시 문제 지문(script 또는 english_content)만을 근거로 삼습니다.
   - 외부 지식은 사용하지 않습니다.
   - 시스템 프롬프트 규칙에 따라 문제 영역에 맞는 해설을 작성합니다:
      - 맥락(context) 영역 → 지문 요약, 문제 요구 사항, 의미·논리적 근거 중심 해설
      - 문법(grammar) 영역 → 문법 요소 설명, 규칙 제시, 문법적 근거 중심 해설
4) 문제 영역은 맥락(context) 영역과 문법(grammar) 영역 중 하나이며, 
   시스템 프롬프트의 규칙에 따라 해당 영역 방식으로 해설을 작성합니다.
5) 상세 해설은 8~10문장, 해설 요약은 3~4 문장으로 작성합니다.
6) 출력 형식은 아래 형식을 유지합니다.

[출력 형식]:
------------------------------------
🔎 문제 {problem_number} (p.{page_number})

✅ 정답: {answer}  
✏️ 사용자의 선택: {user_answer}

💡 상세 해설
- 학생 답안이 틀린 경우 8~10문장 분량의 상세한 한국어 해설 제공

🔹 해설 요약
- 3~4문장으로 간결하게 요약
------------------------------------

아래 JSON 배열을 순서대로 처리하세요:
"""


def safe_int(value, default=0) -> int:
    """
    문자열이나 숫자를 안전하게 정수로 변환
    "01" -> 1, "102" -> 102, 1 -> 1
    """
    if value is None:
        return default
    try:
        return int(value)
    except (ValueError, TypeError):
        return default


def load_answers(answer_file: str = "DB/answer.txt") -> dict:
    """
    정답 파일(answer.txt)을 로드하여 딕셔너리로 반환
    키는 (페이지번호 int, 문제번호 int) 튜플로 저장
    
    Args:
        answer_file (str): 정답 파일 경로
    
    Returns:
        dict: {(페이지 int, 문제번호 int): 정답} 형태의 딕셔너리
    """
    mapping = {}
    
    if not os.path.exists(answer_file):
        return mapping
    
    with open(answer_file, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = [x.strip() for x in line.split(",")]
            if len(parts) >= 3:
                page_str, num_str, ans = parts[0], parts[1], parts[2]
                # 문자열을 정수로 변환하여 저장 ("88", "01", "1") -> (88, 1, "1")
                page_int = safe_int(page_str)
                num_int = safe_int(num_str)
                mapping[(page_int, num_int)] = ans
    return mapping


def load_problems(folder_path: str = "DB/files") -> list:
    """
    database_file 폴더의 모든 JSON 파일을 로드하여 문제 리스트 반환
    
    Returns:
        list: 모든 문제 데이터가 담긴 리스트
    """
    all_problems = []
    
    if not os.path.exists(folder_path):
        return all_problems
    
    json_files = glob.glob(os.path.join(folder_path, "*.json"))
    
    if not json_files:
        return all_problems
    
    for json_file in json_files:
        with open(json_file, encoding="utf-8") as f:
            try:
                data = json.load(f)
                if isinstance(data, list):
                    all_problems.extend(data)
                else:
                    all_problems.append(data)
            except json.JSONDecodeError as e:
                print(f"JSON 파싱 실패: {json_file}, Error: {e}")
                
    return all_problems


def generate_explanation(
    page_number: int, 
    problem_number: int, 
    user_answer: int,
    answer_file: str = "DB/answer.txt",
    problems_folder: str = "DB/files"
) -> Optional[str]:
    """
    학생의 답안을 분석하고 LLM을 통해 해설을 생성하는 메인 함수
    
    Args:
        page_number (int or str): 페이지 번호 (예: 102)
        problem_number (int or str): 문제 번호 (예: 40 또는 1)
        user_answer (int or str): 사용자가 선택한 답안 번호 (예: 5)
        answer_file (str): 정답 파일 경로
        problems_folder (str): 문제 JSON 폴더 경로
    
    Returns:
        str: LLM이 생성한 해설 텍스트
            - 정답인 경우: 정답 확인 메시지만 포함
            - 오답인 경우: 상세 해설 + 해설 요약 포함
            - 에러인 경우: 에러 메시지 문자열
    """
    problems = load_problems(problems_folder)
    real_answers = load_answers(answer_file)
    
    # 입력값을 정수로 변환 (백엔드에서 int로 전달되므로)
    page_int = safe_int(page_number)
    num_int = safe_int(problem_number)
    user_ans = str(user_answer)
    
    # 해당 문제 검색 (정수 비교)
    target = None
    for prob in problems:
        prob_page = safe_int(prob.get("page_number", ""))
        prob_num = safe_int(prob.get("problem_number", 0))
        
        if prob_page == page_int and prob_num == num_int:
            target = prob.copy()
            break
    
    if not target:
        return f"해당 문제를 찾을 수 없습니다. (페이지: {page_int}, 문제번호: {num_int})"
    
    # 실제 정답 가져오기 (정수 튜플로 조회)
    real_ans = real_answers.get((page_int, num_int))
    
    if not real_ans:
        return f"해당 문제의 정답을 찾을 수 없습니다. (페이지: {page_int}, 문제번호: {num_int})"
    
    # 정답인 경우 해설 생성 스킵
    if str(user_ans) == str(real_ans):
        return f"정답입니다! (문제 {num_int}, 페이지 {page_int})"
    
    # 문제 데이터에 정답과 사용자 답안 추가
    target["answer"] = real_ans
    target["user_answer"] = user_ans
    
    # 배열 형태로 래핑 후 JSON 문자열 생성
    problem_json_array = json.dumps([target], ensure_ascii=False, indent=2)
    user_prompt = USER_PROMPT_TEMPLATE + problem_json_array
    
    # OpenAI API 호출
    try:
        response = client.chat.completions.create(
            model="solar-mini",
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0.2,
            max_tokens=2000,
        )
        return response.choices[0].message.content
    
    except Exception as e:
        return f"LLM API 호출 중 오류가 발생했습니다: {str(e)}"


# if __name__ == "__main__":
#     # 테스트 예시
#     result = generate_explanation(page_number=102, problem_number=40, user_answer=5)
#     print(result)