import 'grading_history_entity.dart';

/// 채점 히스토리 Repository 인터페이스
abstract class GradingHistoryRepository {
  /// 여러 academyUserId에 대한 채점 히스토리 조회
  ///
  /// 반환값: academyUserId를 키로 하는 Map
  /// UI에서 필요시 flat하게 합쳐서 사용
  Future<Map<int, List<GradingHistoryEntity>>>
  getGradingHistoriesByAcademyUserIds(List<int> academyUserIds);
}
