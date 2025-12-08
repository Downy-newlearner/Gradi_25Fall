import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/app_logger.dart';
import 'auth_service.dart';

/// Grading History Summary API 응답 DTO
class GradingHistorySummaryResponse {
  final double totalScore;
  final int daysSinceStartOfYear;

  GradingHistorySummaryResponse({
    required this.totalScore,
    required this.daysSinceStartOfYear,
  });

  factory GradingHistorySummaryResponse.fromJson(Map<String, dynamic> json) {
    return GradingHistorySummaryResponse(
      totalScore: (json['total_score'] as num?)?.toDouble() ?? 0.0,
      daysSinceStartOfYear: json['days_since_start_of_year'] as int? ?? 0,
    );
  }
}

/// Continuous Learning API 호출 전용 레이어
class ContinuousLearningApi {
  ContinuousLearningApi({
    required AuthService authService,
    required http.Client httpClient,
  })  : _authService = authService,
        _httpClient = httpClient;

  final AuthService _authService;
  final http.Client _httpClient;

  /// Grading History Summary 조회
  ///
  /// [academyUserId]: 조회할 academyUserId
  ///
  /// 반환값: GradingHistorySummaryResponse
  Future<GradingHistorySummaryResponse> fetchGradingHistorySummary(
    int academyUserId,
  ) async {
    appLog(
      '[continuous_learning:continuous_learning_api] API 호출 시작 - academyUserId: $academyUserId',
    );

    final token = await _authService.ensureValidAccessToken();
    if (token == null) {
      appLog('[continuous_learning:continuous_learning_api] 인증 토큰 없음');
      throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/grading/grading-histories/summary?academyUserId=$academyUserId',
    );

    appLog('[continuous_learning:continuous_learning_api] GET 요청: $uri');
    developer.log('📊 [ContinuousLearningApi] GET $uri');

    final response = await _httpClient
        .get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    appLog(
      '[continuous_learning:continuous_learning_api] 응답 상태 코드: ${response.statusCode}',
    );
    appLog(
      '[continuous_learning:continuous_learning_api] 응답 본문: ${response.body}',
    );
    developer.log('📊 [ContinuousLearningApi] Response status: ${response.statusCode}');

    if (response.statusCode == 401) {
      appLog('[continuous_learning:continuous_learning_api] 인증 실패 (401)');
      throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
    }
    if (response.statusCode != 200) {
      appLog(
        '[continuous_learning:continuous_learning_api] API 호출 실패 - status: ${response.statusCode}',
      );
      throw Exception(
        'Grading History Summary API 호출 실패 (status: ${response.statusCode})',
      );
    }

    try {
      final Map<String, dynamic> data = json.decode(response.body);
      final result = GradingHistorySummaryResponse.fromJson(data);
      appLog(
        '[continuous_learning:continuous_learning_api] 응답 파싱 성공 - totalScore: ${result.totalScore}, daysSinceStartOfYear: ${result.daysSinceStartOfYear}',
      );
      return result;
    } catch (e) {
      appLog(
        '[continuous_learning:continuous_learning_api] 응답 파싱 실패: $e',
      );
      appLog(
        '[continuous_learning:continuous_learning_api] 응답 본문: ${response.body}',
      );
      developer.log('❌ [ContinuousLearningApi] 응답 파싱 실패: $e');
      developer.log('❌ [ContinuousLearningApi] Response body: ${response.body}');
      rethrow;
    }
  }

  /// 여러 academyUserId에 대한 Grading History Summary 조회 (병렬)
  ///
  /// [academyUserIds]: 조회할 academyUserId 리스트
  ///
  /// 반환값: 각 academyUserId별 GradingHistorySummaryResponse 맵
  Future<Map<int, GradingHistorySummaryResponse>>
      fetchGradingHistorySummaries(
    List<int> academyUserIds,
  ) async {
    appLog(
      '[continuous_learning:continuous_learning_api] 여러 academyUserId 조회 시작 - academyUserIds: $academyUserIds',
    );

    // 병렬 처리
    final results = await Future.wait(
      academyUserIds.map((id) => fetchGradingHistorySummary(id)),
    );

    final resultMap = Map.fromIterables(academyUserIds, results);
    appLog(
      '[continuous_learning:continuous_learning_api] 여러 academyUserId 조회 완료 - 결과 개수: ${resultMap.length}',
    );

    return resultMap;
  }
}

