/// 일별 학습 상태 도메인 엔티티
///
/// UI 레이어에서 사용하는 통합 모델로,
/// Assessment와 GradingHistory를 모두 추상화합니다.
///
/// 주의사항:
/// - date는 항상 DateTime(year, month, day) (시간 00:00)로 정규화해서 저장/비교합니다.
class DailyLearningStatus {
  final DateTime date;
  final bool isCompleted;

  // 향후 확장 필드
  final List<BookProgress>? bookProgresses; // 해당 날짜에 푼 문제집별 진행률

  const DailyLearningStatus({
    required this.date,
    required this.isCompleted,
    this.bookProgresses,
  });

  /// 날짜 문자열 (YYYY-MM-DD)
  String get dateString {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// DateTime을 정규화 (시간을 00:00으로 설정)
  ///
  /// Map의 key로 사용하거나 비교할 때 일관성을 보장하기 위해 사용합니다.
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

/// 문제집별 진행률 Value Object
///
/// 특정 날짜에 대한 문제집별 학습 진행률을 표현합니다.
class BookProgress {
  final int? bookId;
  final String bookName;
  final String? bookCoverImageUrl;
  final int todayPages; // 해당 날짜에 푼 페이지 수
  final int accumulatedPages; // 해당 날짜 이전까지 누적 페이지 수
  final int totalPages; // 전체 페이지 수

  const BookProgress({
    this.bookId,
    required this.bookName,
    this.bookCoverImageUrl,
    required this.todayPages,
    required this.accumulatedPages,
    required this.totalPages,
  });

  /// 누적 진행률 (0.0 ~ 1.0)
  double get accumulatedRatio {
    if (totalPages <= 0) return 0.0;
    return (accumulatedPages / totalPages).clamp(0.0, 1.0);
  }

  /// 당일 진행률 (0.0 ~ 1.0)
  double get todayRatio {
    if (totalPages <= 0) return 0.0;
    return (todayPages / totalPages).clamp(0.0, 1.0);
  }

  /// 전체 진행률 (누적 + 당일)
  double get totalRatio {
    if (totalPages <= 0) return 0.0;
    return ((accumulatedPages + todayPages) / totalPages).clamp(0.0, 1.0);
  }
}
