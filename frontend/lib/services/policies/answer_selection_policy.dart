/// 중복 답안 선택 정책
///
/// 같은 문제 번호에 여러 답안이 있을 경우 어떤 답안을 선택할지 결정
class AnswerSelectionPolicy {
  /// 기존 답안을 우선 사용, 없으면 새 답안 사용
  bool? selectAnswer(bool? existing, bool? next) {
    return existing ?? next;
  }
}

