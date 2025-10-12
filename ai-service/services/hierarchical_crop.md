##  output results
Detection/hierarchical_results/
├── page_11/                          # 페이지별 폴더 
│   ├── page_numbers/                 # 1단계: 페이지 번호 crop
│   │   └── page_11_page_number.jpg
│   ├── sections/                     # 2단계: Section 이미지들 (여러 개 존재)
│   │   ├── page_11_section_00.jpg
│   │   └── page_11_section_01.jpg
│   ├── section_00/                   # 3단계: 첫 번째 문제
│   │   ├── problem_number_00.jpg
│   │   ├── answer_1_00.jpg
│   │   └── answer_2_00.jpg
│   └── section_01/                   # 3단계: 두 번째 문제
│       ├── problem_number_00.jpg
│       └── answer_1_00.jpg

## crop pipeline 
1. 순차 처리: page number -> section -> 문제/정답
2. 한 페이지에 대한 여러 section 처리
3. 계층적으로 결과 저장
    - 각각의 class가 개별 이미지로 저장되어 이를 불러와 OCR 적용 가능