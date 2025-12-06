/// 학생 답안 조회 조건 (타입 안전한 Query 객체)
///
/// 필터 조건을 명시적으로 타입으로 표현하여
/// 런타임 오류를 컴파일 타임으로 이동
abstract class StudentAnswerQuery {
  const StudentAnswerQuery();

  /// chapterId + academyUserId로 조회
  factory StudentAnswerQuery.byChapter({
    required int chapterId,
    required int academyUserId,
  }) = ChapterAndAcademyQuery;

  /// studentResponseId로 조회
  factory StudentAnswerQuery.byResponse({
    required int studentResponseId,
  }) = ResponseIdQuery;
}

/// 챕터와 학원 사용자 ID로 조회
class ChapterAndAcademyQuery extends StudentAnswerQuery {
  final int chapterId;
  final int academyUserId;

  const ChapterAndAcademyQuery({
    required this.chapterId,
    required this.academyUserId,
  });
}

/// 학생 응답 ID로 조회
class ResponseIdQuery extends StudentAnswerQuery {
  final int studentResponseId;

  const ResponseIdQuery({required this.studentResponseId});
}

