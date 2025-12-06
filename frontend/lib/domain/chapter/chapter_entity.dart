/// 챕터 도메인 엔티티
///
/// API 응답을 도메인 모델로 변환합니다.
class ChapterEntity {
  final int chapterId;
  final int bookId;
  final int mainChapterNumber;
  final int subChapterNumber;
  final String? chapterName;
  final int chapterStartPage;
  final int chapterEndPage;
  final int chapterStartQuestion;
  final int chapterEndQuestion;
  final int totalChapterQuestion;
  final int studentAnswerCount;

  ChapterEntity({
    required this.chapterId,
    required this.bookId,
    required this.mainChapterNumber,
    required this.subChapterNumber,
    this.chapterName,
    required this.chapterStartPage,
    required this.chapterEndPage,
    required this.chapterStartQuestion,
    required this.chapterEndQuestion,
    required this.totalChapterQuestion,
    required this.studentAnswerCount,
  });

  /// 진행률 계산 (0.0 ~ 1.0)
  ///
  /// **주의**: progress는 "학생이 푼 문제 수 / 전체 문제 수"를 의미합니다.
  /// studentAnswerCount는 서버에서 제공하는 "학생이 답안을 제출한 문제 수"입니다.
  /// 아직 채점되지 않은 문제도 포함될 수 있으므로, 실제 완료율과는 다를 수 있습니다.
  ///
  /// totalChapterQuestion이 0이면 0.0을 반환합니다.
  ///
  /// **경계 조건**:
  /// - totalChapterQuestion == 0 && studentAnswerCount > 0인 경우:
  ///   백엔드 스펙상 불가능한 상황이지만, 안전하게 0.0을 반환합니다.
  double get progress {
    if (totalChapterQuestion <= 0) return 0.0;
    return (studentAnswerCount / totalChapterQuestion).clamp(0.0, 1.0);
  }

  /// 챕터명 포맷팅 "{chapterId}. {chapterName}"
  ///
  /// chapterId를 인덱스로 사용하여 각 챕터를 고유하게 식별합니다.
  /// chapterName이 null이거나 빈 문자열이면 "{chapterId}." 형식으로 반환합니다.
  /// 예: "1. 소인수분해" 또는 "1."
  String get formattedName {
    final base = '$chapterId.';
    if (chapterName == null || chapterName!.trim().isEmpty) {
      return base;
    }
    return '$base $chapterName';
  }

  /// 문제 수 표시 문자열 "{studentAnswerCount} / {totalChapterQuestion}"
  String get problemCountDisplay {
    return '$studentAnswerCount / $totalChapterQuestion';
  }
}
