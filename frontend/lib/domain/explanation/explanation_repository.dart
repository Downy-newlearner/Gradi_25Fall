import 'explanation_entity.dart';
import 'explanation_source.dart';

/// 학생 답안 정보 (findStudentAnswer 응답)
class StudentAnswerInfo {
  final int studentAnswerId;
  final int studentResponseId;
  final int chapterId;
  final int page;
  final int questionNumber;
  final int subQuestionNumber;
  final String answer;
  final String? sectionUrl;
  final double score;
  final bool correct;

  const StudentAnswerInfo({
    required this.studentAnswerId,
    required this.studentResponseId,
    required this.chapterId,
    required this.page,
    required this.questionNumber,
    required this.subQuestionNumber,
    required this.answer,
    this.sectionUrl,
    required this.score,
    required this.correct,
  });
}

/// 문제 해설 조회/생성을 위한 도메인 Repository 인터페이스
abstract class ExplanationRepository {
  /// 학생 답안 정보를 조회한다.
  Future<StudentAnswerInfo> findStudentAnswer(ExplanationSource source);

  /// 이미 생성/저장된 해설을 조회한다. 없으면 null.
  Future<ExplanationEntity?> getExplanation(ExplanationSource source);

  /// 해설 생성을 요청하고, 결과 스냅샷을 반환한다.
  ///
  /// [requestedByUserId]는 누가 해설 생성을 요청했는지에 대한 정보로,
  /// Domain에서는 의미를 해석하지 않고 그대로 전달만 한다.
  /// [academyId]와 [answer]는 findStudentAnswer에서 가져온 정보를 사용한다.
  Future<ExplanationEntity> requestExplanation(
    ExplanationSource source, {
    required int requestedByUserId,
    required int academyId,
    required String answer,
  });
}


