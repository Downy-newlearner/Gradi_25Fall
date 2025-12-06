import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/assessment.dart';

/// SharedPreferences 기반 로컬 스냅샷 저장소.
class AssessmentLocalStore {
  AssessmentLocalStore({SharedPreferences? preferences})
      : _prefs = preferences;

  SharedPreferences? _prefs;

  static const String _cacheVersionKey = 'assessment_cache_version';
  static const int _currentCacheVersion = 3;

  Future<SharedPreferences> get _prefsInstance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> _ensureVersion() async {
    final prefs = await _prefsInstance;
    final version = prefs.getInt(_cacheVersionKey) ?? 1;
    if (version < _currentCacheVersion) {
      await _clearAllWithPrefs(prefs);
      await prefs.setInt(_cacheVersionKey, _currentCacheVersion);
      developer.log(
        '🔄 Assessment 캐시 버전 업데이트: $version -> $_currentCacheVersion',
      );
    }
  }

  String _monthKey(String academyId, int year, int month) {
    final formattedMonth = month.toString().padLeft(2, '0');
    return 'assessments_${academyId}_${year}-$formattedMonth';
  }

  Future<List<Assessment>?> loadDay({
    required String academyId,
    required String date,
  }) async {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return null;

    final monthData = await loadMonth(
      academyId: academyId,
      year: parsed.year,
      month: parsed.month,
    );
    return monthData[date];
  }

  Future<Map<String, List<Assessment>>> loadMonth({
    required String academyId,
    required int year,
    required int month,
  }) async {
    await _ensureVersion();
    final prefs = await _prefsInstance;
    final cacheKey = _monthKey(academyId, year, month);
    final cachedJson = prefs.getString(cacheKey);

    if (cachedJson == null) {
      return {};
    }

    try {
      final Map<String, dynamic> monthData = json.decode(cachedJson);
      final result = <String, List<Assessment>>{};

      monthData.forEach((date, assessmentsJson) {
        try {
          final assessments = (assessmentsJson as List<dynamic>)
              .map((item) => Assessment.fromJson(item))
              .toList();
          result[date] = assessments;
        } catch (e) {
          developer.log('⚠️ Assessment 캐시 파싱 실패 ($date): $e');
        }
      });

      return result;
    } catch (e) {
      developer.log('❌ Assessment 캐시 로드 실패: $e');
      return {};
    }
  }

  Future<void> saveMonth({
    required String academyId,
    required int year,
    required int month,
    required Map<String, List<Assessment>> data,
  }) async {
    await _ensureVersion();
    final prefs = await _prefsInstance;
    final cacheKey = _monthKey(academyId, year, month);

    final Map<String, dynamic> payload = {};
    data.forEach((date, assessments) {
      payload[date] = assessments.map((a) => a.toJson()).toList();
    });

    await prefs.setString(cacheKey, json.encode(payload));
    developer.log('✅ Assessment 캐시 저장: $cacheKey');
  }

  Future<void> clearMonth({
    required String academyId,
    required int year,
    required int month,
  }) async {
    final prefs = await _prefsInstance;
    await prefs.remove(_monthKey(academyId, year, month));
  }

  Future<void> clearAll() async {
    final prefs = await _prefsInstance;
    await _clearAllWithPrefs(prefs);
    await prefs.setInt(_cacheVersionKey, _currentCacheVersion);
  }

  Future<void> _clearAllWithPrefs(SharedPreferences prefs) async {
    final keys = prefs.getKeys().where((key) => key.startsWith('assessments_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}

