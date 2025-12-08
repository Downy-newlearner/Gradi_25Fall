import '../domain/learning/learning_completion_service.dart';
import '../domain/learning/daily_learning_status.dart';
import '../models/assessment.dart';
import '../domain/grading_history/grading_history_entity.dart';

/// LearningCompletionService 구현체
///
/// 순수 함수형으로 설계되어 내부 상태를 가지지 않습니다.
/// 모든 판단은 매개변수로 받은 데이터만으로 수행합니다.
class LearningCompletionServiceImpl implements LearningCompletionService {
  const LearningCompletionServiceImpl();

  @override
  bool isCompleted({
    required DateTime date,
    Map<String, List<Assessment>>? assessmentsByDate,
    Map<String, List<GradingHistoryEntity>>? gradingHistoriesByDate,
  }) {
    final dateStr = _formatDate(date);

    // 우선순위 1: GradingHistory (실제 채점/제출 기록)
    // - 해당 날짜에 gradingDate 가 1개 이상 있으면 "오늘의 학습이 존재"하므로 완료로 판단
    if (gradingHistoriesByDate != null) {
      final histories = gradingHistoriesByDate[dateStr] ?? [];
      if (histories.isNotEmpty) {
        return true;
      }
    }

    // 우선순위 2: Assessment (숙제 완료 기록)
    // - 과제가 하나라도 있으면 "모든 과제가 Y"일 때만 완료로 판단
    // - 과제가 아예 없을 때는 여기서는 완료로 보지 않음
    if (assessmentsByDate != null) {
      final assessments = assessmentsByDate[dateStr] ?? [];
      if (assessments.isEmpty) {
        return false;
      }
      return assessments.every((a) => a.assessStatus == 'Y');
    }

    // GradingHistory, Assessment 모두 없는 경우 → 완료 아님
    return false;
  }

  @override
  Map<DateTime, bool> getCompletionMap({
    required DateTime startDate,
    required DateTime endDate,
    Map<String, List<Assessment>>? assessmentsByDate,
    Map<String, List<GradingHistoryEntity>>? gradingHistoriesByDate,
  }) {
    final map = <DateTime, bool>{};
    var current = DailyLearningStatus.normalizeDate(startDate);
    final normalizedEnd = DailyLearningStatus.normalizeDate(endDate);

    while (current.isBefore(normalizedEnd) ||
        current.isAtSameMomentAs(normalizedEnd)) {
      map[current] = isCompleted(
        date: current,
        assessmentsByDate: assessmentsByDate,
        gradingHistoriesByDate: gradingHistoriesByDate,
      );
      current = current.add(const Duration(days: 1));
    }

    return map;
  }

  @override
  int getConsecutiveDays({
    required DateTime date,
    Map<String, List<Assessment>>? assessmentsByDate,
    Map<String, List<GradingHistoryEntity>>? gradingHistoriesByDate,
  }) {
    var current = DailyLearningStatus.normalizeDate(date);
    int streak = 0;

    // 오늘부터 역순으로 계산
    while (isCompleted(
      date: current,
      assessmentsByDate: assessmentsByDate,
      gradingHistoriesByDate: gradingHistoriesByDate,
    )) {
      streak++;
      current = current.subtract(const Duration(days: 1));
    }

    return streak;
  }

  @override
  bool shouldShowConnector({
    required DateTime date,
    required DateTime nextDate,
    Map<String, List<Assessment>>? assessmentsByDate,
    Map<String, List<GradingHistoryEntity>>? gradingHistoriesByDate,
  }) {
    final normalizedDate = DailyLearningStatus.normalizeDate(date);
    final normalizedNext = DailyLearningStatus.normalizeDate(nextDate);

    return isCompleted(
          date: normalizedDate,
          assessmentsByDate: assessmentsByDate,
          gradingHistoriesByDate: gradingHistoriesByDate,
        ) &&
        isCompleted(
          date: normalizedNext,
          assessmentsByDate: assessmentsByDate,
          gradingHistoriesByDate: gradingHistoriesByDate,
        ) &&
        normalizedNext.month == normalizedDate.month &&
        normalizedNext.year == normalizedDate.year;
  }

  /// 날짜 포맷팅 (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
