import 'student_answer_entity.dart';
import 'student_answer_repository.dart';

/// studentResponseId로 학생 답안 목록을 조회하는 UseCase
class GetStudentAnswersForResponseUseCase {
  final StudentAnswerRepository _repository;

  GetStudentAnswersForResponseUseCase({
    required StudentAnswerRepository repository,
  }) : _repository = repository;

  /// studentResponseId로 학생 답안 목록 조회
  Future<List<StudentAnswerEntity>> call(int studentResponseId) {
    return _repository.getStudentAnswersByResponseId(studentResponseId);
  }
}
