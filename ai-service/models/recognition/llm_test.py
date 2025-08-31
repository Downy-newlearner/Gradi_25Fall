import os
import glob
import base64
from groq import Groq
import dotenv
from datetime import datetime

def encode_image(image_path):
    with open(image_path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")

client = Groq(api_key="") # 여기에 키를 입력

# retry 폴더의 JPG 이미지 파일들을 파일명 순으로 정렬
image_paths = sorted(glob.glob("exp_images/*.jpg")) # exp_images에 테스트 section 이미지를 넣고 작업해! - 다훈 0831

# 결과를 저장할 텍스트 파일 이름 (타임스탬프 포함)
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
output_file = f"llm_results_retry_{timestamp}.txt"

# 결과 저장용 리스트
results = []

for path in image_paths:
    base64_image = encode_image(path) 
    chat_completion = client.chat.completions.create(
        messages=[
            {
                "role": "user",
                "content": [ 
                    {
                        "type": "text",
                        "text":
                            """ 
                            *지시*: 다음 이미지는 한국 수학 문제집의 한 문제에 대한 이미지야. 맥락을 참고하여 이미지를 분석 후 정보를 추출해줘.

                            *맥락*: 문제는 프린트로 인쇄되어있고, 답은 손글씨로 작성돼있어. 너는 학생이 작성한 답안을 인식하여 추출하는 것이 목표야. 네가 답을 추출해주면 이후에 내가 채점을 진행할거야.
                                - 절대 문제를 풀지마.
                                - 학생이 작성한 답안을 추출해.
                                - 하려고 하는 작업이 채점 작업이므로, 틀리게 푼 문제라도 그대로 답안을 추출해.
                                - **학생의 답안을 추출하는게 목표야. 어떻게 작성되어있는지 추출하고 문제를 절대 풀지 마.**
                                

                            *출력 형식*:
                                - 문제 번호: 답\n\n
                                - 문제 번호에는 한 문제에 대한 번호를 작성한다.
                                - 꼬리 문제가 있는 경우에는 답 부분에 이를 나타낸다.

                            *출력 예시*
                                1. 답이 한 개인 경우
                                    - 1: 15
                                        - 설명: 1번 문제, 답이 15라는 의미
                                    - 2: 7^2
                                        - 설명: 2번 문제, 답이 7^2(7의 제곱)이라는 의미

                                2. 답이 여러 개인 경우
                                    - 3: [1, 2, 3]
                                        - 설명: 3번 문제, 답이 1, 2, 그리고 3이라는 의미
                                    - 4: [3, 24]
                                        - 설명: 4번 문제, 답이 3 그리고 24라는 의미
                                    - 10: [ㄱ, ㄷ]
                                        - 설명: 10번 문제, 답이 ㄱ 그리고 ㄷ이라는 의미

                                3. 꼬리 문제(sub_question)가 존재하는 경우
                                    - 5: [1:7, 2:11, 3:[8,9,10,11]]
                                        - 설명: 5번 문제, 꼬리 문제 1번은 답이 7, 꼬리 문제 2번은 답이 11, 꼬리 문제 3번은 답이 8,9,10, 그리고 11이다.
                                    - 6: [1:15, 2:10, 3:22]
                                        - 설명: 6번 문제, 꼬리 문제 1번은 답이 15, 꼬리 문제 2번은 답이 10, 꼬리 문제 3번은 답이 22이다.
                                    - 7: [a:55, b:13]
                                        - 설명: 7번 문제, 꼬리 문제 a는 답이 55, 꼬리 문제 b는 답이 13이다.


                            다른 설명이나 추가 문장은 쓰지 말고 출력 형식에 맞게 결과만 출력해줘.

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
        model="meta-llama/llama-4-scout-17b-16e-instruct",
    )

    # 결과 저장
    result_text = f"Image: {path}\n{chat_completion.choices[0].message.content}\n{'=' * 50}\n"
    results.append(result_text)
    
    # 콘솔에도 출력
    print(f"Image: {path}")
    print(chat_completion.choices[0].message.content)
    print("=" * 50)

# 모든 결과를 텍스트 파일로 저장
with open(output_file, 'w', encoding='utf-8') as f:
    f.write(f"LLM 분석 결과\n생성 시간: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    f.write(f"총 처리된 이미지 수: {len(image_paths)}\n\n")
    f.write("=" * 80 + "\n\n")
    
    for result in results:
        f.write(result)

print(f"\n결과가 {output_file} 파일에 저장되었습니다.")
print(f"총 {len(image_paths)}개의 이미지를 처리했습니다.")