/// 문제를 식별하기 위한 도메인 Value Object
class QuestionIdentifier {
  /// 문제집 ID
  final int bookId;

  /// 챕터 ID
  final int chapterId;

  /// 페이지 번호
  final int page;

  /// 문제 번호
  final int questionNumber;

  /// 서브 문항 번호 (0이면 서브 문항 없음)
  final int subQuestionNumber;

  const QuestionIdentifier({
    required this.bookId,
    required this.chapterId,
    required this.page,
    required this.questionNumber,
    required this.subQuestionNumber,
  });
}


