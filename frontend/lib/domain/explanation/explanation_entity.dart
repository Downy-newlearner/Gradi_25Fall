import '../question/question_identifier.dart';

/// 문제 해설 도메인 엔티티
class ExplanationEntity {
  /// 어떤 문제에 대한 해설인지
  final QuestionIdentifier question;

  /// 해설 텍스트
  final String text;

  const ExplanationEntity({
    required this.question,
    required this.text,
  });
}


