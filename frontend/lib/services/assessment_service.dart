import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import '../models/assessment.dart';
import '../config/api_config.dart';
import 'auth_service.dart';
import 'academy_service.dart';

/// Assessment 데이터 관리 서비스
///
/// 주요 기능:
/// 1. 서버에서 Assessment 데이터 가져오기 (/assessments/assignee/{user_academy_id} API)
/// 2. SharedPreferences에 캐싱 (월별 저장)
/// 3. 메모리 캐시로 빠른 접근
class AssessmentService {
  static final AssessmentService _instance = AssessmentService._internal();
  factory AssessmentService() => _instance;
  AssessmentService._internal();

  final AuthService _authService = AuthService();

  // 메모리 캐시: Map<날짜, List<Assessment>>
  final Map<String, List<Assessment>> _memoryCache = {};

  // 캐시 버전 관리
  static const String _cacheVersionKey = 'assessment_cache_version';
  static const int _currentCacheVersion =
      2; // assessChapter -> assessName, assessClass 추가로 버전 증가

  /// SharedPreferences 키 생성 (월별 저장)
  /// 형식: 'assessments_YYYY-MM'
  static String _getCacheKey(String date) {
    final dateTime = DateTime.parse(date);
    return 'assessments_${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}';
  }

  /// 날짜 문자열 포맷팅 (YYYY-MM-DD)
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 특정 날짜의 Assessment 조회
  ///
  /// 전략:
  /// 1. 메모리 캐시 확인
  /// 2. SharedPreferences 확인
  /// 3. 없으면 해당 월의 데이터를 가져오기 (월 단위 API 호출)
  Future<List<Assessment>> getAssessmentsForDate({
    required String date, // 'YYYY-MM-DD'
    required String userAcademyId,
    bool forceRefresh = false,
  }) async {
    // 1. 메모리 캐시 확인
    if (!forceRefresh && _memoryCache.containsKey(date)) {
      developer.log('✅ Assessment loaded from memory cache: $date');
      return _memoryCache[date]!;
    }

    // 2. SharedPreferences 확인
    if (!forceRefresh) {
      final cached = await _loadFromCache(date);
      if (cached != null && cached.isNotEmpty) {
        _memoryCache[date] = cached;
        developer.log('✅ Assessment loaded from SharedPreferences: $date');
        return cached;
      }
    }

    // 3. 해당 날짜가 속한 월의 데이터를 가져오기
    final dateTime = DateTime.parse(date);
    final monthData = await getAssessmentsForMonth(
      dateTime: dateTime,
      userAcademyId: userAcademyId,
      forceRefresh: forceRefresh,
    );

    // 해당 날짜의 데이터 반환
    return monthData[date] ?? [];
  }

  /// 여러 날짜의 Assessment 일괄 조회
  ///
  /// 최적화: 같은 월의 날짜들은 한 번의 API 호출로 처리
  Future<Map<String, List<Assessment>>> getAssessmentsForDates({
    required List<String> dates, // ['YYYY-MM-DD', ...]
    required String userAcademyId,
  }) async {
    final Map<String, List<Assessment>> result = {};

    // 날짜를 월별로 그룹화
    final Map<String, List<String>> datesByMonth = {};

    for (var date in dates) {
      final dateTime = DateTime.parse(date);
      final monthKey =
          '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}';

      if (!datesByMonth.containsKey(monthKey)) {
        datesByMonth[monthKey] = [];
      }
      datesByMonth[monthKey]!.add(date);
    }

    // 각 월별로 데이터 가져오기
    await Future.wait(
      datesByMonth.entries.map((entry) async {
        final monthKey = entry.key;
        final year = int.parse(monthKey.split('-')[0]);
        final month = int.parse(monthKey.split('-')[1]);

        // 해당 월의 첫 번째 날로 DateTime 생성 (UTC)
        final monthDateTime = DateTime.utc(year, month, 1);

        final monthData = await getAssessmentsForMonth(
          dateTime: monthDateTime,
          userAcademyId: userAcademyId,
        );

        // 해당 월의 요청된 날짜들만 결과에 추가
        for (var date in entry.value) {
          result[date] = monthData[date] ?? [];
        }
      }),
    );

    return result;
  }

  /// 월 단위로 Assessment 데이터 가져오기
  ///
  /// [dateTime]: 해당 월의 DateTime (어떤 날짜든 해당 월로 처리)
  /// [userAcademyId]: 사용자 학원 ID
  ///
  /// 반환: Map<날짜(YYYY-MM-DD), List<Assessment>>
  Future<Map<String, List<Assessment>>> getAssessmentsForMonth({
    required DateTime dateTime, // 해당 월의 DateTime
    required String userAcademyId,
    bool forceRefresh = false,
  }) async {
    // 해당 월의 첫 번째 날로 정규화 (UTC)
    final monthStart = DateTime.utc(dateTime.year, dateTime.month, 1);
    final year = monthStart.year;
    final month = monthStart.month;

    print('🔍 [AssessmentService] 캐시 확인');

    // 1. 메모리 캐시 확인 (해당 월의 모든 날짜 데이터)
    if (!forceRefresh) {
      final cachedMonth = _getMonthFromMemoryCache(year, month);
      if (cachedMonth.isNotEmpty) {
        developer.log('✅ Assessment loaded from memory cache: $year-$month');
        // 캐시에서 로드된 데이터에도 className 업데이트
        await _updateClassNamesInMonthData(cachedMonth);
        return cachedMonth;
      }
    }

    print('🔍 [AssessmentService] SharedPreferences 확인');

    // 2. SharedPreferences 확인
    if (!forceRefresh) {
      final cachedMonth = await _loadMonthFromCache(year, month);
      if (cachedMonth.isNotEmpty) {
        // 메모리 캐시에도 저장
        _saveMonthToMemoryCache(year, month, cachedMonth);
        developer.log(
          '✅ Assessment loaded from SharedPreferences: $year-$month',
        );
        // 캐시에서 로드된 데이터에도 className 업데이트
        await _updateClassNamesInMonthData(cachedMonth);
        return cachedMonth;
      }
    }

    print('🔍 [AssessmentService] API 호출');
    // 3. API 호출
    developer.log('🔄 Fetching assessment from server: $year-$month');
    return await _fetchMonthFromServer(
      dateTime: monthStart,
      userAcademyId: userAcademyId,
    );
  }

  /// 서버에서 월 단위 데이터 가져오기
  Future<Map<String, List<Assessment>>> _fetchMonthFromServer({
    required DateTime dateTime, // 해당 월의 첫 번째 날 (UTC)
    required String userAcademyId,
  }) async {
    try {
      final token = await _authService.ensureValidAccessToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
      }

      final uri = ApiConfig.getAssessmentsAssigneeUri(
        userAcademyId,
        dateTime: dateTime,
      );

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // API 응답 파싱
        final dynamic data = json.decode(response.body);
        final Map<String, List<Assessment>> monthData = {};
        final Set<String> assigneeIds = {}; // 클래스 정보 조회를 위한 assigneeId 수집

        if (data is List) {
          // 1단계: Assessment 파싱 및 assigneeId 수집
          for (var item in data) {
            final assessment = Assessment.fromJson(item);
            final deadlineDate = item['assessDeadline'] as String?;

            if (deadlineDate != null) {
              final formattedDate = _normalizeDate(deadlineDate);

              if (!monthData.containsKey(formattedDate)) {
                monthData[formattedDate] = [];
              }
              monthData[formattedDate]!.add(assessment);

              // assigneeId 수집 (assessClass에 저장된 assigneeId)
              if (assessment.assessClass.isNotEmpty) {
                assigneeIds.add(assessment.assessClass);
              }
            }
          }

          // 2단계: 클래스 정보 조회 및 업데이트
          await _updateClassNamesInMonthData(monthData);
        } else if (data is Map) {
          // Map 형태 처리 (기존 로직)
          data.forEach((key, value) {
            if (value is List) {
              final assessments = value
                  .map((item) => Assessment.fromJson(item))
                  .toList();
              monthData[key.toString()] = assessments;
            }
          });
        }

        // 메모리 캐시에 저장
        _saveMonthToMemoryCache(dateTime.year, dateTime.month, monthData);

        // SharedPreferences에 저장
        await _saveMonthToCache(dateTime.year, dateTime.month, monthData);

        return monthData;
      } else if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  /// 월 데이터의 assessClass를 className으로 업데이트
  Future<void> _updateClassNamesInMonthData(
    Map<String, List<Assessment>> monthData,
  ) async {
    // 1. 모든 assigneeId 수집
    final Set<String> assigneeIds = {};
    monthData.forEach((date, assessments) {
      for (var assessment in assessments) {
        // assessClass가 숫자로만 구성되어 있으면 assigneeId로 간주
        // (className은 한글이 포함되어 있음)
        if (assessment.assessClass.isNotEmpty &&
            RegExp(r'^\d+$').hasMatch(assessment.assessClass)) {
          assigneeIds.add(assessment.assessClass);
        }
      }
    });

    if (assigneeIds.isEmpty) {
      print('ℹ️ [AssessmentService] 업데이트할 assigneeId가 없음');
      return;
    }

    // 2. 클래스 정보 조회
    try {
      print('🔍 [AssessmentService] 조회할 assigneeIds: ${assigneeIds.toList()}');
      final classMap = await AcademyService().getClassesByAssigneeIds(
        assigneeIds.toList(),
      );
      print('🔍 [AssessmentService] 받은 classMap: $classMap');

      // 3. Assessment의 assessClass를 className으로 업데이트
      int updatedCount = 0;
      monthData.forEach((date, assessments) {
        for (var i = 0; i < assessments.length; i++) {
          final assessment = assessments[i];
          // 숫자로만 구성된 assessClass만 업데이트 (이미 className인 경우 스킵)
          if (RegExp(r'^\d+$').hasMatch(assessment.assessClass)) {
            print(
              '🔍 [AssessmentService] 매칭 시도: assessClass=${assessment.assessClass}, classMap에 있는 키: ${classMap.keys.toList()}',
            );
            final className = classMap[assessment.assessClass];
            print('🔍 [AssessmentService] 매칭 결과: className=$className');
            if (className != null && className.isNotEmpty) {
              // assessClass를 className으로 업데이트
              assessments[i] = assessment.copyWith(assessClass: className);
              updatedCount++;
              print(
                '✅ [AssessmentService] 업데이트 완료: ${assessment.assessClass} -> $className',
              );
            } else {
              print(
                '⚠️ [AssessmentService] className을 찾을 수 없음: assessClass=${assessment.assessClass}',
              );
            }
          }
        }
      });
      print('✅ [AssessmentService] 총 $updatedCount개 Assessment 업데이트됨');
    } catch (e) {
      print('❌ [AssessmentService] 클래스 정보 조회 실패: $e');
      // 클래스 정보 조회 실패해도 Assessment는 표시 (assessClass는 assigneeId로 유지)
    }
  }

  /// SharedPreferences에서 로드
  Future<List<Assessment>?> _loadFromCache(String date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(date);
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson == null) {
        return null;
      }

      final Map<String, dynamic> monthData = json.decode(cachedJson);
      final dateAssessments = monthData[date] as List<dynamic>?;

      if (dateAssessments == null) {
        return null;
      }

      return dateAssessments.map((item) => Assessment.fromJson(item)).toList();
    } catch (e) {
      developer.log('❌ Error loading assessment from cache: $e');
      return null;
    }
  }

  /// 이번 달 남은 날짜 목록 생성
  List<String> getRemainingDatesInMonth() {
    final now = DateTime.now();
    final today = now.day;
    final lastDay = DateTime(now.year, now.month + 1, 0).day;

    return List.generate(lastDay - today, (index) {
      final date = DateTime(now.year, now.month, today + index + 1);
      return _formatDate(date);
    });
  }

  /// 메모리 캐시에서 특정 월의 데이터 가져오기
  Map<String, List<Assessment>> _getMonthFromMemoryCache(int year, int month) {
    final result = <String, List<Assessment>>{};
    final monthPrefix = '${year}-${month.toString().padLeft(2, '0')}-';

    _memoryCache.forEach((date, assessments) {
      if (date.startsWith(monthPrefix)) {
        result[date] = assessments;
      }
    });

    return result;
  }

  /// 메모리 캐시에 특정 월의 데이터 저장
  void _saveMonthToMemoryCache(
    int year,
    int month,
    Map<String, List<Assessment>> monthData,
  ) {
    monthData.forEach((date, assessments) {
      _memoryCache[date] = assessments;
    });
  }

  /// 캐시 버전 확인 및 마이그레이션
  Future<void> _migrateCacheIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final version = prefs.getInt(_cacheVersionKey) ?? 1;

      if (version < _currentCacheVersion) {
        developer.log(
          '🔄 Migrating assessment cache from version $version to $_currentCacheVersion',
        );

        // 기존 캐시 삭제 (구조가 크게 변경되어 마이그레이션보다 삭제가 안전)
        await _clearAllCache();

        // 버전 업데이트
        await prefs.setInt(_cacheVersionKey, _currentCacheVersion);
        developer.log('✅ Cache migration completed');
      }
    } catch (e) {
      developer.log('❌ Error during cache migration: $e');
    }
  }

  /// 모든 Assessment 캐시 삭제 (내부용)
  Future<void> _clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (var key in keys) {
        if (key.startsWith('assessments_')) {
          await prefs.remove(key);
        }
      }

      _memoryCache.clear();
      developer.log('✅ All assessment cache cleared');
    } catch (e) {
      developer.log('❌ Error clearing cache: $e');
    }
  }

  /// 모든 Assessment 캐시 삭제 (public)
  /// 메모리 캐시와 SharedPreferences 캐시를 모두 초기화합니다.
  Future<void> clearAllAssessmentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (var key in keys) {
        if (key.startsWith('assessments_')) {
          await prefs.remove(key);
        }
      }

      _memoryCache.clear();
      developer.log('✅ All assessment cache cleared');
      print('✅ [AssessmentService] 모든 Assessment 캐시 초기화 완료');
    } catch (e) {
      developer.log('❌ Error clearing cache: $e');
      print('❌ [AssessmentService] 캐시 초기화 실패: $e');
    }
  }

  /// SharedPreferences에서 월 단위 데이터 로드
  Future<Map<String, List<Assessment>>> _loadMonthFromCache(
    int year,
    int month,
  ) async {
    try {
      // 캐시 버전 확인
      await _migrateCacheIfNeeded();

      final prefs = await SharedPreferences.getInstance();
      final cacheKey =
          'assessments_${year}-${month.toString().padLeft(2, '0')}';
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson == null) {
        return {};
      }

      final Map<String, dynamic> monthData = json.decode(cachedJson);
      final result = <String, List<Assessment>>{};

      monthData.forEach((date, assessmentsJson) {
        try {
          final assessments = (assessmentsJson as List<dynamic>)
              .map((item) => Assessment.fromJson(item))
              .toList();
          result[date] = assessments;
        } catch (e) {
          developer.log('⚠️ Error parsing cached assessment for $date: $e');
          // 파싱 실패한 날짜는 건너뛰기
        }
      });

      return result;
    } catch (e) {
      developer.log('❌ Error loading assessment from cache: $e');
      return {};
    }
  }

  /// SharedPreferences에 월 단위 데이터 저장
  Future<void> _saveMonthToCache(
    int year,
    int month,
    Map<String, List<Assessment>> monthData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey =
          'assessments_${year}-${month.toString().padLeft(2, '0')}';

      final Map<String, dynamic> jsonData = {};
      monthData.forEach((date, assessments) {
        jsonData[date] = assessments.map((a) => a.toJson()).toList();
      });

      await prefs.setString(cacheKey, json.encode(jsonData));
      developer.log('✅ Assessment saved to cache: $year-$month');
    } catch (e) {
      developer.log('❌ Error saving assessment to cache: $e');
    }
  }

  /// 날짜 형식 정규화 (YYYY-MM-DD 형식으로 변환)
  String _normalizeDate(String date) {
    // 다양한 날짜 형식을 YYYY-MM-DD로 변환
    // 예: '2024-10-15', '2024/10/15', '20241015', '2025-11-23T22:59:59' (ISO 8601) 등
    try {
      // 이미 YYYY-MM-DD 형식인 경우 (길이 10)
      if (date.length == 10 && date.contains('-') && !date.contains('T')) {
        return date;
      }

      // ISO 8601 형식인 경우 (예: '2025-11-23T22:59:59' 또는 '2025-11-23T22:59:59.000Z')
      if (date.contains('T')) {
        final parsed = DateTime.parse(date);
        return _formatDate(parsed);
      }

      // YYYYMMDD 형식인 경우
      if (date.length == 8 && !date.contains('-') && !date.contains('/')) {
        return '${date.substring(0, 4)}-${date.substring(4, 6)}-${date.substring(6, 8)}';
      }

      // YYYY/MM/DD 형식인 경우
      if (date.contains('/')) {
        return date.replaceAll('/', '-');
      }

      // 기타 형식 파싱 시도
      final parsed = DateTime.parse(date);
      return _formatDate(parsed);
    } catch (e) {
      developer.log('⚠️ [AssessmentService] 날짜 형식 변환 실패: $date, error: $e');
      return date; // 변환 실패 시 원본 반환
    }
  }

  /// 오늘 날짜 문자열 반환
  String getTodayDateString() {
    return _formatDate(DateTime.now());
  }

  /// 메모리 캐시 초기화
  void clearMemoryCache() {
    _memoryCache.clear();
    developer.log('✅ Assessment memory cache cleared');
  }

  /// 특정 월의 캐시 삭제
  Future<void> clearMonthCache(String date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(date);
      await prefs.remove(cacheKey);

      // 메모리 캐시에서도 삭제
      final monthPrefix = cacheKey.replaceFirst('assessments_', '');
      final year = int.parse(monthPrefix.split('-')[0]);
      final month = int.parse(monthPrefix.split('-')[1]);
      final prefix = '${year}-${month.toString().padLeft(2, '0')}-';
      _memoryCache.removeWhere((date, _) => date.startsWith(prefix));

      developer.log('✅ Assessment cache cleared for month: $cacheKey');
    } catch (e) {
      developer.log('❌ Error clearing month cache: $e');
    }
  }
}
