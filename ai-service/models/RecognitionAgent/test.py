import os
from typing import TypedDict, List
from langgraph.graph import StateGraph, START, END, MessageGraph
from langgraph.prebuilt import create_empty_graph

# 1. 상태(State) 정의
class PageProcessingState(TypedDict):
    page_image_path: str
    metadata: dict # "book_name", "page"
    segmented_problems: List[dict] # [ { "image": ..., "bbox": ..., "type": "problem" }, ... ]
    results: List[dict] # 최종 결과가 담길 리스트
    current_problem_index: int

# 2. 노드(Node) 정의
def preprocess_and_segment_node(state: PageProcessingState):
    # 페이지 이미지 전체를 받아 각 문제 영역을 분할
    print("페이지 전처리 및 문제 영역 분할을 시작합니다...")
    # 멀티모달 LLM 호출 (Gemini 1.5 Pro)
    # ...
    # state.segmented_problems 업데이트
    # ...
    state['current_problem_index'] = 0
    return state

def process_single_problem_node(state: PageProcessingState):
    # 현재 문제 인덱스를 사용하여 개별 문제 처리
    problem = state['segmented_problems'][state['current_problem_index']]
    
    # 문제 번호 및 학생 답안 인식
    # ... Google Document AI 호출 ...
    problem_number = "..."
    student_answer = "..."
    
    # 정오답 판별
    # ... Gemini 1.5 Pro 호출 ...
    is_correct = "..."
    
    # 결과 저장
    state['results'].append({
        "problem_number": problem_number,
        "student_answer": student_answer,
        "is_correct": is_correct
    })
    
    # 다음 문제로 인덱스 이동
    state['current_problem_index'] += 1
    return state

def final_json_node(state: PageProcessingState):
    # 모든 문제 처리가 완료되면 JSON 형식으로 변환하여 반환
    final_output = {
        "MetaData": state['metadata'],
        "Results": state['results']
    }
    # JSON 파일 생성 및 저장
    print(f"최종 결과가 {state['metadata']['page']} 페이지의 JSON 파일로 저장되었습니다.")
    return final_output

# 3. 조건부 라우팅 함수 정의
def should_continue_loop(state: PageProcessingState):
    # 모든 문제가 처리되었는지 확인
    if state['current_problem_index'] < len(state['segmented_problems']):
        return "continue"
    else:
        return "end_loop"

# 4. 그래프(Graph) 구성
builder = StateGraph(PageProcessingState)

# 노드 추가
builder.add_node("preprocess_and_segment", preprocess_and_segment_node)
builder.add_node("process_single_problem", process_single_problem_node)
builder.add_node("final_json_assembly", final_json_node)

# 엣지 정의
builder.add_edge(START, "preprocess_and_segment")
builder.add_edge("preprocess_and_segment", "process_single_problem")

# 루프 정의
builder.add_conditional_edges(
    "process_single_problem",
    should_continue_loop,
    {
        "continue": "process_single_problem", # 다음 문제를 위해 자신으로 돌아감
        "end_loop": "final_json_assembly"    # 루프 종료 후 최종 JSON 생성
    }
)

builder.add_edge("final_json_assembly", END)

# 그래프 컴파일
app = builder.compile()

# 실행 예시 (외부에서 호출)
# sample_page_image_path = "path/to/page_image.jpg"
# inputs = {
#     "page_image_path": sample_page_image_path,
#     "metadata": { "book_name": "쎈", "page": "1" }
# }
# final_result = app.invoke(inputs)
# print(final_result)