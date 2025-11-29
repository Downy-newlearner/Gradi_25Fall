import 'dart:async';
import 'dart:developer' as developer;

import '../models/assessment.dart';
import 'academy_service.dart';
import 'assessment_api.dart';
import 'assessment_local_store.dart';

/// Assessment 데이터를 위한 단일 진입점.
///
/// 메모리 캐시 → SharedPreferences → API 순서로 읽고,
/// API 성공 시 SharedPreferences → 메모리 순으로 동기화합니다.
class AssessmentRepository {
  AssessmentRepository({
    AssessmentApi? api,
    AssessmentLocalStore? localStore,
    AcademyService? academyService,
  }) : _api = api ?? AssessmentApi(),
       _localStore = localStore ?? AssessmentLocalStore(),
       _academyService = academyService ?? AcademyService();

  final AssessmentApi _api;
  final AssessmentLocalStore _localStore;
  final AcademyService _academyService;

  final Map<String, List<Assessment>> _memoryCache = {};

  /// 날짜 단위 키 생성 (academyId|YYYY-MM-DD)
  String _cacheKey(String academyId, String date) => '$academyId|$date';

  DateTime _monthStart(DateTime dateTime) =>
      DateTime.utc(dateTime.year, dateTime.month, 1);

  /// 읽기: 메모리 → 로컬 → API
  Future<List<Assessment>> getForDate({
    required String academyId,
    required String date,
    bool forceRefresh = false,
  }) async {
    final key = _cacheKey(academyId, date);

    if (!forceRefresh && _memoryCache.containsKey(key)) {
      return _memoryCache[key]!;
    }

    if (!forceRefresh) {
      final cached = await _localStore.loadDay(
        academyId: academyId,
        date: date,
      );
      if (cached != null) {
        _memoryCache[key] = cached;
        _refreshMonthFromServerInBackground(
          academyId: academyId,
          monthStart: _monthStart(DateTime.parse(date)),
        );
        return cached;
      }
    }

    final monthData = await getForMonth(
      academyId: academyId,
      dateTime: DateTime.parse(date),
      forceRefresh: forceRefresh,
    );
    return monthData[date] ?? [];
  }

  Future<Map<String, List<Assessment>>> getForDates({
    required String academyId,
    required List<String> dates,
    bool forceRefresh = false,
  }) async {
    final Map<String, List<Assessment>> result = {};
    final Map<String, List<String>> datesByMonth = {};

    for (final date in dates) {
      final parsed = DateTime.parse(date);
      final monthKey =
          '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}';
      datesByMonth.putIfAbsent(monthKey, () => []).add(date);
    }

    for (final entry in datesByMonth.entries) {
      final year = int.parse(entry.key.split('-')[0]);
      final month = int.parse(entry.key.split('-')[1]);
      final monthData = await getForMonth(
        academyId: academyId,
        dateTime: DateTime.utc(year, month, 1),
        forceRefresh: forceRefresh,
      );
      for (final date in entry.value) {
        result[date] = monthData[date] ?? [];
      }
    }

    return result;
  }

  Future<Map<String, List<Assessment>>> getForMonth({
    required String academyId,
    required DateTime dateTime,
    bool forceRefresh = false,
  }) async {
    final monthStart = _monthStart(dateTime);
    final year = monthStart.year;
    final month = monthStart.month;
    final prefix = '$academyId|${year}-${month.toString().padLeft(2, '0')}-';

    if (!forceRefresh) {
      final fromMemory = _getMonthFromMemoryCache(prefix);
      if (fromMemory.isNotEmpty) {
        await _updateClassNamesInMonthData(fromMemory);
        return fromMemory;
      }
    }

    if (!forceRefresh) {
      final fromLocal = await _localStore.loadMonth(
        academyId: academyId,
        year: year,
        month: month,
      );
      if (fromLocal.isNotEmpty) {
        _saveMonthToMemoryCache(academyId, fromLocal);
        await _updateClassNamesInMonthData(fromLocal);
        _refreshMonthFromServerInBackground(
          academyId: academyId,
          monthStart: monthStart,
        );
        return fromLocal;
      }
    }

    final fromServer = await _api.fetchAssessmentsForMonth(
      userAcademyId: academyId,
      monthStart: monthStart,
    );

    await _updateClassNamesInMonthData(fromServer);
    await _saveMonthSnapshot(
      academyId: academyId,
      monthStart: monthStart,
      data: fromServer,
    );
    return fromServer;
  }

  Future<void> clearAll() async {
    _memoryCache.clear();
    await _localStore.clearAll();
    developer.log('✅ Assessment 캐시 전체 초기화');
  }

  void clearMemory() {
    _memoryCache.clear();
  }

  Future<void> _saveMonthSnapshot({
    required String academyId,
    required DateTime monthStart,
    required Map<String, List<Assessment>> data,
  }) async {
    _saveMonthToMemoryCache(academyId, data);
    await _localStore.saveMonth(
      academyId: academyId,
      year: monthStart.year,
      month: monthStart.month,
      data: data,
    );
  }

  void _saveMonthToMemoryCache(
    String academyId,
    Map<String, List<Assessment>> monthData,
  ) {
    monthData.forEach((date, assessments) {
      _memoryCache[_cacheKey(academyId, date)] = assessments;
    });
  }

  Map<String, List<Assessment>> _getMonthFromMemoryCache(String prefix) {
    final result = <String, List<Assessment>>{};
    _memoryCache.forEach((key, value) {
      if (key.startsWith(prefix)) {
        final date = key.split('|')[1];
        result[date] = value;
      }
    });
    return result;
  }

  void _refreshMonthFromServerInBackground({
    required String academyId,
    required DateTime monthStart,
  }) {
    Future(() async {
      try {
        final fresh = await _api.fetchAssessmentsForMonth(
          userAcademyId: academyId,
          monthStart: monthStart,
        );
        await _updateClassNamesInMonthData(fresh);
        await _saveMonthSnapshot(
          academyId: academyId,
          monthStart: monthStart,
          data: fresh,
        );
        developer.log('🔄 Assessment 백그라운드 새로고침 완료');
      } catch (e) {
        developer.log('⚠️ Assessment 백그라운드 새로고침 실패: $e');
      }
    });
  }

  Future<void> _updateClassNamesInMonthData(
    Map<String, List<Assessment>> monthData,
  ) async {
    final Set<String> assigneeIds = {};
    monthData.forEach((_, assessments) {
      for (final assessment in assessments) {
        if (assessment.assessClass.isNotEmpty &&
            RegExp(r'^\d+$').hasMatch(assessment.assessClass)) {
          assigneeIds.add(assessment.assessClass);
        }
      }
    });

    if (assigneeIds.isEmpty) {
      return;
    }

    try {
      final classMap = await _academyService.getClassesByAssigneeIds(
        assigneeIds.toList(),
      );

      monthData.forEach((date, assessments) {
        for (var i = 0; i < assessments.length; i++) {
          final assessment = assessments[i];
          if (RegExp(r'^\d+$').hasMatch(assessment.assessClass)) {
            final className = classMap[assessment.assessClass];
            if (className != null && className.isNotEmpty) {
              assessments[i] = assessment.copyWith(assessClass: className);
            }
          }
        }
      });
    } catch (e) {
      developer.log('⚠️ 클래스 정보 업데이트 실패: $e');
    }
  }
}
