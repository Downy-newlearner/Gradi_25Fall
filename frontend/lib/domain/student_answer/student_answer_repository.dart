import 'student_answer_entity.dart';
import 'student_answer_update.dart';
import 'student_answer_query.dart';

/// Student Answer Repository 인터페이스
abstract class StudentAnswerRepository {
  /// studentResponseId로 학생 답안 목록 조회
  Future<List<StudentAnswerEntity>> getStudentAnswersByResponseId(
    int studentResponseId,
  );

  /// Query 객체 기반 학생 답안 조회
  ///
  /// [query]: 조회 조건 (chapterId + academyUserId 또는 studentResponseId)
  ///
  /// 반환: 학생 답안 엔티티 리스트
  Future<List<StudentAnswerEntity>> getStudentAnswers(
    StudentAnswerQuery query,
  );

  /// 수정된 답안들을 서버에 저장
  ///
  /// [updates]: 수정된 답안 목록 (studentAnswerId와 새로운 answer 포함)
  ///
  /// 참고: 현재는 answer만 수정하고, is_correct(정답 여부)는 서버 기준 그대로 유지됩니다.
  /// 향후 정답 여부 재계산 기능이 필요하면 별도 API로 확장 예정입니다.
  Future<void> updateStudentAnswers(List<StudentAnswerUpdate> updates);
}
