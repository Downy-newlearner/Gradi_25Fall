import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/app_logger.dart';
import 'auth_service.dart';

/// API 응답 DTO (서버 응답 구조 그대로)
///
/// API 응답: flat array 형태
/// [{student_response_id: ..., academy_user_id: 20, ...}, {student_response_id: ..., academy_user_id: 25, ...}]
class GradingHistoryApiResponse {
  final int studentResponseId; // student_response_id
  final int academyUserId; // academy_user_id
  final int? assessId; // assess_id
  final int? bookId; // book_id
  final String? bookName; // book_name
  final String? bookImageUrl; // book_image_url
  final int responseStartPage; // response_start_page
  final int responseEndPage; // response_end_page
  final int unrecognizedResponseCount; // unrecognized_response_count
  final String createdAt; // created_at (ISO 8601)
  final String? updatedAt; // updated_at

  GradingHistoryApiResponse({
    required this.studentResponseId,
    required this.academyUserId,
    this.assessId,
    this.bookId,
    this.bookName,
    this.bookImageUrl,
    required this.responseStartPage,
    required this.responseEndPage,
    this.unrecognizedResponseCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory GradingHistoryApiResponse.fromJson(Map<String, dynamic> json) {
    return GradingHistoryApiResponse(
      studentResponseId: json['student_response_id'] as int? ?? 0,
      academyUserId: json['academy_user_id'] as int? ?? 0,
      assessId: json['assess_id'] as int?,
      bookId: json['book_id'] as int?,
      bookName: json['book_name'] as String?,
      bookImageUrl: json['book_image_url'] as String?,
      responseStartPage: json['response_start_page'] as int? ?? 0,
      responseEndPage: json['response_end_page'] as int? ?? 0,
      unrecognizedResponseCount:
          json['unrecognized_response_count'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
    );
  }
}

/// Grading History API 호출 전용 레이어
class GradingHistoryApi {
  GradingHistoryApi({AuthService? authService, http.Client? httpClient})
    : _authService = authService ?? AuthService(),
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  /// 여러 academyUserId에 대한 채점 히스토리 조회
  ///
  /// [academyUserIds]: 조회할 academyUserId 리스트
  ///
  /// 반환값: flat array 형태의 GradingHistoryApiResponse 리스트
  /// API 응답: [{...}, {...}] 형태의 배열
  ///
  /// 현재는 전체 로드 방식이며, 필요 시 페이징 API로 확장 가능
  Future<List<GradingHistoryApiResponse>> fetchGradingHistories(
    List<int> academyUserIds,
  ) async {
    // 비즈니스 흐름 로그: appLog 사용
    appLog(
      '[grading_history:grading_history_api] API 호출 시작 - academyUserIds: $academyUserIds',
    );

    // 1. 토큰 확인
    final token = await _authService.ensureValidAccessToken();
    if (token == null) {
      appLog('[grading_history:grading_history_api] 인증 토큰 없음');
      throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
    }

    // 2. academyUserIds를 콤마로 구분한 문자열로 변환
    final idsParam = academyUserIds.join(',');
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/grading/student-responses/histories?academyUserIds=$idsParam',
    );

    appLog('[grading_history:grading_history_api] GET 요청: $uri');
    // 디버깅 디테일 로그: developer.log 사용
    developer.log('📚 [GradingHistoryApi] GET $uri');

    // 3. API 호출
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
      '[grading_history:grading_history_api] 응답 상태 코드: ${response.statusCode}',
    );
    appLog('[grading_history:grading_history_api] 응답 본문: ${response.body}');
    developer.log(
      '📚 [GradingHistoryApi] Response status: ${response.statusCode}',
    );

    // 4. 에러 처리
    if (response.statusCode == 401) {
      appLog('[grading_history:grading_history_api] 인증 실패 (401)');
      throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
    }
    if (response.statusCode != 200) {
      appLog(
        '[grading_history:grading_history_api] API 호출 실패 - status: ${response.statusCode}',
      );
      throw Exception('채점 히스토리 조회에 실패했습니다. (status: ${response.statusCode})');
    }

    // 5. JSON 파싱
    try {
      final List<dynamic> data = json.decode(response.body);
      final result = data
          .map(
            (item) => GradingHistoryApiResponse.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();

      appLog(
        '[grading_history:grading_history_api] 응답 파싱 성공 - 항목 수: ${result.length}',
      );
      return result;
    } catch (e) {
      appLog('[grading_history:grading_history_api] 응답 파싱 실패: $e');
      appLog('[grading_history:grading_history_api] 응답 본문: ${response.body}');
      developer.log('❌ [GradingHistoryApi] 응답 파싱 실패: $e');
      developer.log('❌ [GradingHistoryApi] Response body: ${response.body}');
      rethrow;
    }
  }
}
