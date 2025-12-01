/// 문제 풀이 상태 모델 (Application Layer)
///
/// Domain Entity를 UI에 맞게 변환한 모델
/// UI는 이 모델을 받아서 자유롭게 렌더링
class QuestionStatusModel {
  final int questionNumber;
  final bool? isCorrect; // null = 안 풀음, true = 맞음, false = 틀림

  const QuestionStatusModel({
    required this.questionNumber,
    required this.isCorrect,
  });
}

