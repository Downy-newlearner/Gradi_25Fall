import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../domain/workbook/workbook_repository.dart';
import '../domain/workbook/workbook_summary_entity.dart';
import 'workbook_api.dart';
import '../data/mappers/workbook_mapper.dart';
import 'academy_service.dart';

/// Workbook Repository 구현체
///
/// API 호출, className 조회, 캐싱을 담당합니다.
class WorkbookRepositoryImpl implements WorkbookRepository {
  WorkbookRepositoryImpl({
    required WorkbookApi api,
    required WorkbookMapper mapper,
    required AcademyService academyService,
  })  : _api = api,
        _mapper = mapper,
        _academyService = academyService;

  final WorkbookApi _api;
  final WorkbookMapper _mapper;
  final AcademyService _academyService;

  static const String _cacheKeyPrefix = 'workbook_summaries_';

  @override
  Future<Map<int, List<WorkbookSummaryEntity>>>
  getWorkbookSummariesByAcademyUserIds(List<int> academyUserIds) async {
    if (academyUserIds.isEmpty) {
      return {};
    }

    try {
      // 1. Workbook API 호출
      final apiResponses = await _api.fetchWorkbooks(academyUserIds);

      // 2. className 조회 (AcademyService 사용)
      // ⚠️ 주의: academyUserId와 assigneeId는 1:1 관계입니다.
      final classNameMapStr = await _academyService.getClassesByAssigneeIds(
        academyUserIds.map((id) => id.toString()).toList(),
      );

      // 3. String → int 키 변환
      final classNameMap = <int, String?>{};
      for (final id in academyUserIds) {
        final className = classNameMapStr[id.toString()];
        // 빈 문자열도 null로 처리
        classNameMap[id] = (className != null && className.isNotEmpty)
            ? className
            : null;
      }

      // 4. Mapper로 변환 (실제 classNameMap 전달)
      final summariesMap = await _mapper.convertApiResponsesToSummaries(
        apiResponses,
        classNameMap,
      );

      // 5. 캐시 저장
      for (final entry in summariesMap.entries) {
        await cacheWorkbookSummaries(entry.key, entry.value);
      }

      return summariesMap;
    } catch (e) {
      developer.log('❌ [WorkbookRepository] API 호출 실패: $e');

      // 캐시에서 로드 시도
      final cachedMap = <int, List<WorkbookSummaryEntity>>{};
      for (final id in academyUserIds) {
        final cached = await getCachedWorkbookSummaries(id);
        if (cached != null && cached.isNotEmpty) {
          cachedMap[id] = cached;
        }
      }

      if (cachedMap.isNotEmpty) {
        developer.log('✅ [WorkbookRepository] 캐시에서 로드 성공');
        return cachedMap;
      }

      rethrow;
    }
  }

  @override
  Future<List<WorkbookSummaryEntity>?> getCachedWorkbookSummaries(
    int academyUserId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$academyUserId';
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson == null) {
        return null;
      }

      final List<dynamic> data = json.decode(cachedJson);
      final result = data
          .map((item) => WorkbookSummaryEntity.fromJson(item))
          .toList();
      return result;
    } catch (e) {
      developer.log('⚠️ [WorkbookRepository] 캐시 로드 실패: $e');
      return null;
    }
  }

  @override
  Future<void> cacheWorkbookSummaries(
    int academyUserId,
    List<WorkbookSummaryEntity> summaries,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$academyUserId';
      final jsonData = json.encode(summaries.map((s) => s.toJson()).toList());
      await prefs.setString(cacheKey, jsonData);
      developer.log('✅ [WorkbookRepository] 캐시 저장 완료: $academyUserId');
    } catch (e) {
      developer.log('⚠️ [WorkbookRepository] 캐시 저장 실패: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_cacheKeyPrefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
      developer.log('✅ [WorkbookRepository] 캐시 초기화 완료');
    } catch (e) {
      developer.log('⚠️ [WorkbookRepository] 캐시 초기화 실패: $e');
    }
  }
}
