import '../../domain/question/question_identifier.dart';
import '../../domain/explanation/explanation_entity.dart';

/// Explanation API 응답을 도메인 엔티티로 변환하는 Mapper
class ExplanationMapper {
  /// POST /grading/student-answers/explanation 응답 파싱
  ExplanationEntity fromPostResponse(Map<String, dynamic> json) {
    final explanation =
        json['explanation'] as Map<String, dynamic>? ?? const <String, dynamic>{};

    final question = QuestionIdentifier(
      bookId: explanation['book_id'] as int? ?? 0,
      chapterId: explanation['chapter_id'] as int? ?? 0,
      page: explanation['page'] as int? ?? 0,
      questionNumber: explanation['question_number'] as int? ?? 0,
      subQuestionNumber: explanation['sub_question_number'] as int? ?? 0,
    );

    final text = explanation['explanation'] as String? ?? '';

    return ExplanationEntity(
      question: question,
      text: text,
    );
  }

  /// GET /grading/student-answers/get-explanation 응답 파싱
  ExplanationEntity fromGetResponse(Map<String, dynamic> json) {
    final question = QuestionIdentifier(
      bookId: json['book_id'] as int? ?? 0,
      chapterId: json['chapter_id'] as int? ?? 0,
      page: json['page'] as int? ?? 0,
      questionNumber: json['question_number'] as int? ?? 0,
      subQuestionNumber: json['sub_question_number'] as int? ?? 0,
    );

    final text = json['explanation'] as String? ?? '';

    return ExplanationEntity(
      question: question,
      text: text,
    );
  }
}


