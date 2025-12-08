/// 답안 수정 정보 (도메인 Value Object)
class StudentAnswerUpdate {
  final int studentAnswerId;
  final String newAnswer; // 수정된 답안

  const StudentAnswerUpdate({
    required this.studentAnswerId,
    required this.newAnswer,
  });
}
