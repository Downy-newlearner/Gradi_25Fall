import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/grading_history/grading_history_entity.dart';
import '../domain/grading_history/grading_history_repository.dart';
import 'grading_history_api.dart';
import 'grading_history_use_case.dart';
import 'academy_service.dart';

/// Grading History Repository 구현체
///
/// API 호출, className 조회, 캐싱을 담당합니다.
class GradingHistoryRepositoryImpl implements GradingHistoryRepository {
  GradingHistoryRepositoryImpl({
    GradingHistoryApi? api,
    GradingHistoryUseCase? useCase,
    AcademyService? academyService,
  }) : _api = api ?? GradingHistoryApi(),
       _useCase = useCase ?? GradingHistoryUseCase(),
       _academyService = academyService ?? AcademyService();

  final GradingHistoryApi _api;
  final GradingHistoryUseCase _useCase;
  final AcademyService _academyService;

  static const String _cacheKeyPrefix = 'grading_history_';

  @override
  Future<Map<int, List<GradingHistoryEntity>>>
  getGradingHistoriesByAcademyUserIds(List<int> academyUserIds) async {
    if (academyUserIds.isEmpty) {
      return {};
    }

    try {
      // 1. API 호출 (flat array 반환)
      final apiResponses = await _api.fetchGradingHistories(academyUserIds);

      // 2. className 조회
      final classNameMapStr = await _academyService.getClassesByAssigneeIds(
        academyUserIds.map((id) => id.toString()).toList(),
      );

      // 3. String → int 키 변환
      final classNameMap = <int, String?>{};
      for (final id in academyUserIds) {
        final className = classNameMapStr[id.toString()];
        classNameMap[id] = (className != null && className.isNotEmpty)
            ? className
            : null;
      }

      // 4. UseCase로 변환
      final entities = _useCase.convertApiResponsesToEntities(
        apiResponses,
        classNameMap,
      );

      // 5. academyUserId별 그룹핑
      // ⚠️ 히스토리가 없는 academyUserId도 빈 리스트로 포함 (캐싱을 위해)
      final groupedMap = <int, List<GradingHistoryEntity>>{};

      // 먼저 모든 academyUserId에 대해 빈 리스트 초기화
      for (final id in academyUserIds) {
        groupedMap[id] = [];
      }

      // 실제 엔티티들을 그룹핑
      for (final entity in entities) {
        groupedMap[entity.academyUserId]?.add(entity);
      }

      // 6. 캐시 저장 (academyUserId별로, 빈 리스트도 저장)
      for (final entry in groupedMap.entries) {
        await _cacheGradingHistories(entry.key, entry.value);
      }

      return groupedMap;
    } catch (e) {
      developer.log('❌ [GradingHistoryRepository] API 호출 실패: $e');

      // 캐시에서 로드 시도
      final cachedMap = <int, List<GradingHistoryEntity>>{};
      for (final id in academyUserIds) {
        final cached = await _getCachedGradingHistories(id);
        if (cached != null) {
          // 빈 리스트도 포함 (히스토리가 없는 경우도 캐시에 저장됨)
          cachedMap[id] = cached;
        }
      }

      if (cachedMap.isNotEmpty) {
        developer.log('✅ [GradingHistoryRepository] 캐시에서 로드 성공');
        return cachedMap;
      }

      rethrow;
    }
  }

  /// 캐시 저장
  Future<void> _cacheGradingHistories(
    int academyUserId,
    List<GradingHistoryEntity> entities,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$academyUserId';
      final jsonList = entities.map((e) => e.toCacheJson()).toList();
      await prefs.setString(cacheKey, jsonEncode(jsonList));
    } catch (e) {
      developer.log('⚠️ [GradingHistoryRepository] 캐시 저장 실패: $e');
    }
  }

  /// 캐시에서 로드
  Future<List<GradingHistoryEntity>?> _getCachedGradingHistories(
    int academyUserId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$academyUserId';
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson == null) return null;

      final List<dynamic> jsonList = jsonDecode(cachedJson);
      return jsonList
          .map(
            (json) => GradingHistoryEntity.fromCacheJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      developer.log('⚠️ [GradingHistoryRepository] 캐시 로드 실패: $e');
      return null;
    }
  }
}
