import base64
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
