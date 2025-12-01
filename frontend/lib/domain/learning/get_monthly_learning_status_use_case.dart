import 'daily_learning_status.dart';

/// 월별 학습 상태 조회 UseCase 인터페이스
///
/// Domain Layer의 추상 인터페이스로,
/// Data Layer에서 구현합니다.
abstract class GetMonthlyLearningStatusUseCase {
  /// 특정 월의 일별 학습 상태 조회
  ///
  /// [month]: 조회할 월 (첫 번째 날짜로 표현, 예: DateTime(2025, 11, 1))
  ///
  /// 반환값: 해당 월의 모든 날짜에 대한 DailyLearningStatus 리스트
  /// 날짜 순서대로 정렬되어 반환됩니다.
  /// 각 DailyLearningStatus.date는 정규화된 DateTime(year, month, day)입니다.
  Future<List<DailyLearningStatus>> call(DateTime month);

  /// 특정 날짜의 학습 상태 조회
  ///
  /// [date]: 조회할 날짜
  ///
  /// 반환값: 해당 날짜의 DailyLearningStatus
  /// date는 정규화된 DateTime(year, month, day)입니다.
  Future<DailyLearningStatus?> getStatusForDate(DateTime date);
}

