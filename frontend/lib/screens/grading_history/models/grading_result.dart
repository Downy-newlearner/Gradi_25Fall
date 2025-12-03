import '../../../domain/student_answer/student_answer_entity.dart';

/// UI 전용 모델 (EditGradingResultPage에서 사용)
class GradingResult {
  final int questionNumber;
  final int subQuestionNumber;
  final int studentAnswerId; // 수정 시 필요
  final int? chapterId; // 단일 수정 API 호출 시 사용
  String recognizedAnswer; // 수정 가능
  final String correctStatus; // '정답' 또는 '오답'
  // 참고: 답안 수정 시 서버에서 정답 여부를 재계산하여 반환합니다.

  GradingResult({
    required this.questionNumber,
    required this.subQuestionNumber,
    required this.studentAnswerId,
    required this.chapterId,
    required this.recognizedAnswer,
    required this.correctStatus,
  });

  /// 문제 번호 표시 문자열
  ///
  /// 예: questionNumber=1, subQuestionNumber=0 → "1"
  ///     questionNumber=1, subQuestionNumber=2 → "1-2"
  String get displayNumber {
    if (subQuestionNumber == 0) {
      return questionNumber.toString();
    }
    return '$questionNumber-$subQuestionNumber';
  }

  /// answer가 비어있는지 확인 (인식 실패 여부 판단용)
  ///
  /// getter로 구현하여 recognizedAnswer 변경 시 자동으로 반영됨
  /// UI 레이어에서는 공백만 있는 경우도 빈 값으로 처리합니다.
  bool get isEmptyAnswer => recognizedAnswer.trim().isEmpty;

  /// StudentAnswerEntity에서 UI 모델로 변환
  factory GradingResult.fromEntity(StudentAnswerEntity entity) {
    // 정답 여부: is_correct에 따라
    final correctStatus = entity.isCorrect == true ? '정답' : '오답';

    return GradingResult(
      questionNumber: entity.questionNumber,
      subQuestionNumber: entity.subQuestionNumber,
      studentAnswerId: entity.studentAnswerId,
      chapterId: entity.chapterId,
      recognizedAnswer: entity.answer,
      correctStatus: correctStatus,
    );
  }
}
