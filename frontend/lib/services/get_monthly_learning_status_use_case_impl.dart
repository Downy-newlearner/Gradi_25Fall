import '../domain/learning/get_monthly_learning_status_use_case.dart';
import '../domain/learning/daily_learning_status.dart';
import '../domain/learning/learning_completion_service.dart';
import 'assessment_repository.dart';
import '../domain/grading_history/grading_history_repository.dart';
import '../domain/grading_history/grading_history_entity.dart';

/// GetMonthlyLearningStatusUseCase 구현체
///
/// Data Layer에서 Domain Layer 인터페이스를 구현합니다.
///
/// 주의사항:
/// - 이 UseCase는 "월별 학습 상태 조회"에 집중합니다.
/// - 사용자/학원 컨텍스트는 호출하는 쪽(UI Layer)에서 결정하여
///   필요한 데이터(academyId, academyUserIds)를 매개변수로 전달받습니다.
class GetMonthlyLearningStatusUseCaseImpl
    implements GetMonthlyLearningStatusUseCase {
  final AssessmentRepository _assessmentRepository;
  final GradingHistoryRepository _gradingHistoryRepository;
  final LearningCompletionService _completionService;

  GetMonthlyLearningStatusUseCaseImpl({
    required AssessmentRepository assessmentRepository,
    required GradingHistoryRepository gradingHistoryRepository,
    required LearningCompletionService completionService,
  })  : _assessmentRepository = assessmentRepository,
        _gradingHistoryRepository = gradingHistoryRepository,
        _completionService = completionService;

  @override
  Future<List<DailyLearningStatus>> call(DateTime month) async {
    // 월의 첫 날로 정규화
    final normalizedMonth = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(normalizedMonth.year, normalizedMonth.month + 1, 0)
        .day;

    // 빈 상태 리스트 생성 (데이터가 없어도 모든 날짜에 대해 상태 반환)
    final statuses = <DailyLearningStatus>[];

    for (int day = 1; day <= lastDay; day++) {
      final date = DailyLearningStatus.normalizeDate(
        DateTime(normalizedMonth.year, normalizedMonth.month, day),
      );
      statuses.add(DailyLearningStatus(
        date: date,
        isCompleted: false, // 기본값, 아래에서 데이터 로드 후 업데이트
      ));
    }

    return statuses;
  }

  /// 사용자 학원 컨텍스트를 받아서 실제 데이터를 로드하고 완료 여부를 판단
  ///
  /// 이 메서드는 UI Layer에서 호출하여 사용자/학원 정보를 전달받습니다.
  /// UseCase 자체는 사용자 컨텍스트를 모르지만, 이 헬퍼 메서드를 통해
  /// 실제 데이터를 로드하고 완료 여부를 업데이트합니다.
  ///
  /// [month]: 조회할 월
  /// [academyId]: Assessment 조회용 academyId (userAcademyId)
  /// [academyUserIds]: GradingHistory 조회용 academyUserId 리스트
  ///
  /// 반환값: 완료 여부가 업데이트된 DailyLearningStatus 리스트
  Future<List<DailyLearningStatus>> callWithContext({
    required DateTime month,
    required String academyId,
    required List<int> academyUserIds,
  }) async {
    // 1. 해당 월의 Assessment 데이터 로드
    final assessmentsByDate = await _assessmentRepository.getForMonth(
      academyId: academyId,
      dateTime: month,
    );

    // 2. 해당 월의 GradingHistory 데이터 로드
    final gradingHistoriesByAcademyUserId =
        await _gradingHistoryRepository
            .getGradingHistoriesByAcademyUserIds(academyUserIds);

    // 3. GradingHistory를 날짜별로 그룹화 (해당 월에 속하는 것만)
    final gradingHistoriesByDate = <String, List<GradingHistoryEntity>>{};
    gradingHistoriesByAcademyUserId.forEach((academyUserId, histories) {
      for (var history in histories) {
        // 해당 월에 속하는지 확인
        if (history.gradingDate.year == month.year &&
            history.gradingDate.month == month.month) {
          final dateStr = _formatDate(history.gradingDate);
          gradingHistoriesByDate.putIfAbsent(dateStr, () => []).add(history);
        }
      }
    });

    // 4. 해당 월의 모든 날짜에 대해 DailyLearningStatus 생성
    final normalizedMonth = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(normalizedMonth.year, normalizedMonth.month + 1, 0)
        .day;

    final statuses = <DailyLearningStatus>[];

    for (int day = 1; day <= lastDay; day++) {
      final date = DailyLearningStatus.normalizeDate(
        DateTime(normalizedMonth.year, normalizedMonth.month, day),
      );

      // LearningCompletionService로 완료 여부 판단
      final isCompleted = _completionService.isCompleted(
        date: date,
        assessmentsByDate: assessmentsByDate,
        gradingHistoriesByDate: gradingHistoriesByDate,
      );

      statuses.add(DailyLearningStatus(
        date: date,
        isCompleted: isCompleted,
        // Phase 3에서 bookProgresses 추가 예정
      ));
    }

    return statuses;
  }

  @override
  Future<DailyLearningStatus?> getStatusForDate(DateTime date) async {
    final month = DateTime(date.year, date.month, 1);
    final statuses = await call(month);
    final normalizedDate = DailyLearningStatus.normalizeDate(date);

    try {
      return statuses.firstWhere(
        (status) => DailyLearningStatus.normalizeDate(status.date) == normalizedDate,
      );
    } catch (e) {
      return DailyLearningStatus(date: normalizedDate, isCompleted: false);
    }
  }

  /// 날짜 포맷팅 (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

