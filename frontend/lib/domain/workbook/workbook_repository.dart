import 'workbook_summary_entity.dart';

/// Workbook Repository 인터페이스
/// 
/// 문제집 요약 정보를 조회하는 Repository의 추상 인터페이스입니다.
abstract class WorkbookRepository {
  /// 여러 academyUserId에 대한 문제집 요약 목록 조회 (한 번에)
  /// 
  /// 여러 academyUserId를 한 번에 조회하여 각 academyUserId별로
  /// WorkbookSummaryEntity 리스트를 반환합니다.
  /// 
  /// [academyUserIds]: 조회할 academyUserId 리스트
  /// 
  /// 반환값: Map<academyUserId, List<WorkbookSummaryEntity>>
  Future<Map<int, List<WorkbookSummaryEntity>>> getWorkbookSummariesByAcademyUserIds(
    List<int> academyUserIds,
  );

  /// 캐시에서 문제집 요약 목록 조회
  /// 
  /// [academyUserId]: 조회할 academyUserId
  /// 
  /// 반환값: 캐시된 WorkbookSummaryEntity 리스트 또는 null
  Future<List<WorkbookSummaryEntity>?> getCachedWorkbookSummaries(int academyUserId);

  /// 문제집 요약 목록 캐시 저장
  /// 
  /// [academyUserId]: 저장할 academyUserId
  /// [summaries]: 저장할 WorkbookSummaryEntity 리스트
  Future<void> cacheWorkbookSummaries(
    int academyUserId,
    List<WorkbookSummaryEntity> summaries,
  );

  /// 캐시 초기화
  Future<void> clearCache();
}

