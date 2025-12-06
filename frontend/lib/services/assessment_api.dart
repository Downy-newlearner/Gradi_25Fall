import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/assessment.dart';
import '../utils/app_logger.dart';
import 'auth_service.dart';

/// 서버와 통신하여 Assessment 데이터를 가져오는 전용 API 레이어.
class AssessmentApi {
  AssessmentApi({
    required AuthService authService,
    required http.Client httpClient,
  }) : _authService = authService,
       _httpClient = httpClient;

  final AuthService _authService;
  final http.Client _httpClient;

  /// 지정된 학원 사용자의 특정 월 데이터를 조회합니다.
  ///
  /// [monthStart]는 해당 월의 첫째 날(UTC)이어야 합니다.
  Future<Map<String, List<Assessment>>> fetchAssessmentsForMonth({
    required String userAcademyId,
    required DateTime monthStart,
  }) async {
    final token = await _authService.ensureValidAccessToken();
    if (token == null) {
      throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
    }

    final uri = ApiConfig.getAssessmentsAssigneeUri(
      userAcademyId,
      dateTime: monthStart,
    );
    print(
      '[AssessmentApi] GET $uri | academy: $userAcademyId, monthStart: $monthStart',
    );

    // appLog로 API 호출 정보 기록
    appLog(
      '[continuous_learning:assessment_api] API 호출 시작 - URL: $uri, userAcademyId: $userAcademyId, monthStart: $monthStart',
    );

    final response = await _httpClient
        .get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));
    final previewLength = response.body.length > 200
        ? 200
        : response.body.length;
    final previewBody = response.body.substring(0, previewLength);
    print(
      '[AssessmentApi] Response status: ${response.statusCode} | body preview: $previewBody',
    );

    // appLog로 API 응답 정보 기록
    appLog(
      '[continuous_learning:assessment_api] API 응답 - status: ${response.statusCode}, body length: ${response.body.length}, preview: $previewBody',
    );

    if (response.statusCode == 401) {
      throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
    }
    if (response.statusCode != 200) {
      throw Exception('Assessment API 호출 실패 (status: ${response.statusCode})');
    }

    try {
      final dynamic data = json.decode(response.body);
      final Map<String, List<Assessment>> monthData = {};

      if (data is List) {
        for (final item in data) {
          final assessment = Assessment.fromJson(item);
          final deadlineDate = item['assessDeadline'] as String?;
          if (deadlineDate == null) continue;

          final formattedDate = _normalizeDate(deadlineDate);
          monthData.putIfAbsent(formattedDate, () => []).add(assessment);
        }
      } else if (data is Map) {
        data.forEach((key, value) {
          if (value is List) {
            monthData[key.toString()] = value
                .map((item) => Assessment.fromJson(item))
                .toList();
          }
        });
      } else {
        developer.log('⚠️ [AssessmentApi] 알 수 없는 응답 형식: $data');
      }

      // appLog로 파싱된 데이터 정보 기록
      appLog(
        '[continuous_learning:assessment_api] 데이터 파싱 완료 - 날짜별 과제 수: ${monthData.length}개 날짜',
      );
      monthData.forEach((date, assessments) {
        appLog(
          '[continuous_learning:assessment_api]   - $date: ${assessments.length}개 과제',
        );
      });

      return monthData;
    } catch (e) {
      developer.log('❌ [AssessmentApi] 응답 파싱 실패: $e');
      rethrow;
    }
  }

  /// 다양한 날짜 문자열을 YYYY-MM-DD 형식으로 정규화합니다.
  String _normalizeDate(String date) {
    try {
      if (date.length == 10 && date.contains('-') && !date.contains('T')) {
        return date;
      }

      if (date.contains('T')) {
        final parsed = DateTime.parse(date);
        return _formatDate(parsed);
      }

      if (date.length == 8 && !date.contains('-') && !date.contains('/')) {
        return '${date.substring(0, 4)}-${date.substring(4, 6)}-${date.substring(6, 8)}';
      }

      if (date.contains('/')) {
        return date.replaceAll('/', '-');
      }

      final parsed = DateTime.parse(date);
      return _formatDate(parsed);
    } catch (e) {
      developer.log('⚠️ [AssessmentApi] 날짜 정규화 실패: $date, error: $e');
      return date;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
