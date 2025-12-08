import 'student_answer_repository.dart';
import 'student_answer_update.dart';

/// 수정된 답안들을 서버에 저장하는 UseCase
class UpdateStudentAnswersUseCase {
  final StudentAnswerRepository _repository;

  UpdateStudentAnswersUseCase({required StudentAnswerRepository repository})
    : _repository = repository;

  /// 수정된 답안들을 서버에 저장
  ///
  /// [updates]: 수정된 답안 목록
  Future<void> call(List<StudentAnswerUpdate> updates) async {
    if (updates.isEmpty) return;
    await _repository.updateStudentAnswers(updates);
  }
}
