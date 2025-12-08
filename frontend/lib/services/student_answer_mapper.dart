import '../domain/student_answer/student_answer_entity.dart';
import 'student_answer_api.dart';

/// Student Answer API 응답을 도메인 엔티티로 변환하는 Mapper
///
/// Data Layer 내부 유틸리티로, DTO → Entity 변환만 담당
class StudentAnswerMapper {
  /// API 응답 리스트를 도메인 엔티티 리스트로 변환
  List<StudentAnswerEntity> fromApi(List<StudentAnswerApiResponse> responses) {
    return responses.map((response) {
      return StudentAnswerEntity(
        studentAnswerId: response.studentAnswerId,
        studentResponseId: response.studentResponseId,
        chapterId: response.chapterId,
        page: response.page,
        questionNumber: response.questionNumber,
        subQuestionNumber: response.subQuestionNumber,
        answer: response.answer,
        sectionUrl: response.sectionUrl,
        isCorrect: response.isCorrect,
        score: response.score,
      );
    }).toList();
  }
}
