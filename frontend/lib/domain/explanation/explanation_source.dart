import '../question/question_identifier.dart';

/// 해설 조회/생성에 필요한 외부 식별자 + 문제 식별자 묶음
class ExplanationSource {
  /// 학생 답안 응답 ID
  final int studentResponseId;

  /// 학원 사용자 ID
  final int academyUserId;

  /// 어떤 문제에 대한 해설인지
  final QuestionIdentifier question;

  const ExplanationSource({
    required this.studentResponseId,
    required this.academyUserId,
    required this.question,
  });
}


