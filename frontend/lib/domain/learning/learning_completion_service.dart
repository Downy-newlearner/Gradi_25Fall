import '../../models/assessment.dart';
import '../grading_history/grading_history_entity.dart';

/// 학습 완료 여부 판단 Service 인터페이스
///
/// Domain Layer의 추상 인터페이스로,
/// "어떤 날을 완료로 볼 것인가"라는 도메인 규칙을 정의합니다.
///
/// 주의: 이 인터페이스는 순수 함수형으로 설계되어 있습니다.
/// 내부 상태를 가지지 않으며, 매개변수로 받은 데이터만으로 판단합니다.
abstract class LearningCompletionService {
  /// 특정 날짜가 완료되었는지 판단
  ///
  /// [date]: 판단할 날짜 (정규화된 DateTime)
  /// [assessmentsByDate]: 날짜별 Assessment 맵 (YYYY-MM-DD 형식의 키)
  /// [gradingHistoriesByDate]: 날짜별 GradingHistory 맵 (YYYY-MM-DD 형식의 키)
  ///
  /// 반환값: 완료되었으면 true
  ///
  /// 규칙:
  /// 1. GradingHistory가 있으면 → GradingHistory 기준으로 판단 (우선순위 1)
  ///    - 해당 날짜에 gradingDate가 있는 GradingHistory가 1개 이상 있으면 완료
  /// 2. GradingHistory가 없으면 → Assessment 기준으로 판단 (우선순위 2)
  ///    - 해당 날짜의 Assessment 중 하나라도 assessStatus == 'Y'이면 완료
  /// 3. 둘 다 없으면 → false
  ///
  /// 하루에 여러 번 푼 경우:
  /// - GradingHistory: 여러 history가 있어도 1개 이상이면 완료로 판단
  /// - Assessment: 여러 개 있어도 하나라도 'Y'면 완료로 판단
  bool isCompleted({
    required DateTime date,
    Map<String, List<Assessment>>? assessmentsByDate,
    Map<String, List<GradingHistoryEntity>>? gradingHistoriesByDate,
  });

  /// 날짜 범위의 완료 여부 맵 조회
  ///
  /// [startDate]: 시작 날짜 (정규화된 DateTime)
  /// [endDate]: 종료 날짜 (정규화된 DateTime, 포함)
  /// [assessmentsByDate]: 날짜별 Assessment 맵
  /// [gradingHistoriesByDate]: 날짜별 GradingHistory 맵
  ///
  /// 반환값: 날짜별 완료 여부 맵 (정규화된 DateTime을 키로 사용)
  Map<DateTime, bool> getCompletionMap({
    required DateTime startDate,
    required DateTime endDate,
    Map<String, List<Assessment>>? assessmentsByDate,
    Map<String, List<GradingHistoryEntity>>? gradingHistoriesByDate,
  });

  /// 연속 학습일 계산
  ///
  /// [date]: 기준 날짜 (이 날짜부터 역순으로 계산, 정규화된 DateTime)
  /// [assessmentsByDate]: 날짜별 Assessment 맵
  /// [gradingHistoriesByDate]: 날짜별 GradingHistory 맵
  ///
  /// 반환값: 연속 학습일 수
  int getConsecutiveDays({
    required DateTime date,
    Map<String, List<Assessment>>? assessmentsByDate,
    Map<String, List<GradingHistoryEntity>>? gradingHistoriesByDate,
  });

  /// 연속 학습일 연결선 표시 여부 판단
  ///
  /// [date]: 현재 날짜 (정규화된 DateTime)
  /// [nextDate]: 다음 날짜 (정규화된 DateTime)
  /// [assessmentsByDate]: 날짜별 Assessment 맵
  /// [gradingHistoriesByDate]: 날짜별 GradingHistory 맵
  ///
  /// 반환값: 두 날짜 모두 완료되고 같은 월에 속하면 true
  bool shouldShowConnector({
    required DateTime date,
    required DateTime nextDate,
    Map<String, List<Assessment>>? assessmentsByDate,
    Map<String, List<GradingHistoryEntity>>? gradingHistoriesByDate,
  });
}

