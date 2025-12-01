/// 학생 답안 도메인 엔티티
class StudentAnswerEntity {
  final int studentAnswerId; // 필수 (0이면 유효하지 않음)
  final int studentResponseId; // 필수 (0이면 유효하지 않음)
  final int? chapterId;
  final int page;
  final int questionNumber;
  final int subQuestionNumber;
  final String answer; // 문자열 (객관식/주관식 모두 포함)
  final String? sectionUrl; // 문제 이미지 URL (향후 확장)
  final bool? isCorrect; // null = 답안 없음, true = 맞음, false = 틀림
  final double score;

  const StudentAnswerEntity({
    required this.studentAnswerId,
    required this.studentResponseId,
    this.chapterId,
    required this.page,
    required this.questionNumber,
    required this.subQuestionNumber,
    required this.answer,
    this.sectionUrl,
    required this.isCorrect,
    required this.score,
  });

  /// answer가 비어있는지 확인 (인식 실패 여부 판단용)
  ///
  /// 현재는 answer가 비어있으면 인식 실패로 간주하지만,
  /// 나중에 서버에서 별도의 인식 실패 플래그가 생기면 그걸 사용할 예정
  ///
  /// 참고: UI 레이어에서는 공백만 있는 경우도 빈 값으로 처리하지만,
  /// Domain 레이어에서는 공백도 유효한 답으로 취급합니다.
  bool get isEmptyAnswer => answer.isEmpty;
}
