# WorkbookDetailPage API 응답 구조

## API 엔드포인트

**Method**: `GET`  
**Endpoint**: `/grading/chapter/book/{book_id}/user/{academy_user_id}`  
**Headers**:

- `Content-Type: application/json`
- `Authorization: Bearer {token}`

**Path Parameters**:

- `book_id` (int): 문제집 ID
- `academy_user_id` (int): 학원 사용자 ID

## 응답 구조

### 응답 형식

```json
[
  {
    "chapter_id": 1,
    "book_id": 1,
    "main_chapter_number": 1,
    "sub_chapter_number": 0,
    "chapter_name": "Gradi의 이해",
    "chapter_start_page": 0,
    "chapter_end_page": 0,
    "chapter_start_question": 0,
    "chapter_end_question": 0,
    "total_chapter_question": 20,
    "student_answer_count": 0
  },
  ...
]
```

**응답 타입**: JSON 배열 (`List<ChapterApiResponse>`)

### 응답 필드 상세

| 필드명 (JSON)            | 타입             | 필수 여부 | 기본값 | 설명                                 |
| ------------------------ | ---------------- | --------- | ------ | ------------------------------------ |
| `chapter_id`             | `int`            | 필수      | -      | 챕터 고유 ID                         |
| `book_id`                | `int`            | 필수      | -      | 문제집 ID                            |
| `main_chapter_number`    | `int`            | 선택      | `0`    | 대단원 번호 (정렬 기준)              |
| `sub_chapter_number`     | `int`            | 선택      | `0`    | 소단원 번호 (정렬 기준)              |
| `chapter_name`           | `string \| null` | 선택      | `null` | 챕터 이름                            |
| `chapter_start_page`     | `int`            | 선택      | `0`    | 챕터 시작 페이지                     |
| `chapter_end_page`       | `int`            | 선택      | `0`    | 챕터 종료 페이지                     |
| `chapter_start_question` | `int`            | 선택      | `0`    | 챕터 시작 문제 번호                  |
| `chapter_end_question`   | `int`            | 선택      | `0`    | 챕터 종료 문제 번호                  |
| `total_chapter_question` | `int`            | 선택      | `0`    | 챕터 전체 문제 수                    |
| `student_answer_count`   | `int`            | 선택      | `0`    | 학생이 제출한 답안 수 (완료 문제 수) |

## 정렬 규칙

UseCase에서 자동으로 정렬됩니다:

1. `main_chapter_number` 오름차순
2. `sub_chapter_number` 오름차순

## 도메인 엔티티 변환

API 응답(`ChapterApiResponse`)은 도메인 엔티티(`ChapterEntity`)로 변환되며, 추가로 다음 계산된 속성을 제공합니다:

- `progress` (double): `student_answer_count / total_chapter_question` (0.0 ~ 1.0)
- `formattedName` (string): `"{chapterId}. {chapterName}"` 형식 (chapterId를 인덱스로 사용)
- `problemCountDisplay` (string): `"{studentAnswerCount} / {totalChapterQuestion}"` 형식

## 에러 처리

- **401 Unauthorized**: 인증 실패 (토큰 만료 또는 유효하지 않음)
- **200 OK**: 성공 (빈 배열일 수 있음)
- **기타 상태 코드**: API 호출 실패 예외 발생

## 참고 파일

- API 호출: `frontend/lib/data/chapter/chapter_api.dart`
- Repository: `frontend/lib/data/chapter/chapter_repository_impl.dart`
- UseCase: `frontend/lib/domain/chapter/get_chapters_for_book_use_case.dart`
- Entity: `frontend/lib/domain/chapter/chapter_entity.dart`
