import '../../services/student_answer_api.dart';

/// 단일 학생 답안을 수정하는 UseCase
class UpdatedStudentAnswer {
  final int studentAnswerId;
  final int studentResponseId;
  final int questionNumber;
  final int subQuestionNumber;
  final String recognizedAnswer;
  final bool? isCorrect;
  final double score;

  UpdatedStudentAnswer({
    required this.studentAnswerId,
    required this.studentResponseId,
    required this.questionNumber,
    required this.subQuestionNumber,
    required this.recognizedAnswer,
    required this.isCorrect,
    required this.score,
  });
}

class UpdateSingleStudentAnswerUseCase {
  final StudentAnswerApi _api;

  UpdateSingleStudentAnswerUseCase({required StudentAnswerApi api})
      : _api = api;

  Future<UpdatedStudentAnswer> call({
    required int studentAnswerId,
    required int studentResponseId,
    required int questionNumber,
    required int subQuestionNumber,
    required String newAnswer,
    required int chapterId,
  }) async {
    final dto = await _api.updateSingleStudentAnswer(
      studentAnswerId: studentAnswerId,
      studentResponseId: studentResponseId,
      questionNumber: questionNumber,
      subQuestionNumber: subQuestionNumber,
      answer: newAnswer,
      chapterId: chapterId,
    );

    return UpdatedStudentAnswer(
      studentAnswerId: dto.studentAnswerId,
      studentResponseId: dto.studentResponseId,
      questionNumber: dto.questionNumber,
      subQuestionNumber: dto.subQuestionNumber,
      recognizedAnswer: dto.answer,
      isCorrect: dto.correct,
      score: dto.score,
    );
  }
}


