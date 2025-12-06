import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/app_logger.dart';
import 'auth_service.dart';

/// API 응답 DTO (서버 응답 구조 그대로)
class SectionImageApiResponse {
  final String url; // S3 base URL
  final String key; // S3 object key

  SectionImageApiResponse({
    required this.url,
    required this.key,
  });

  factory SectionImageApiResponse.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String?;
    final key = json['key'] as String?;

    if (url == null || url.isEmpty) {
      throw FormatException(
        '[SectionImageApiResponse.fromJson] url is null or empty',
        json,
      );
    }
    if (key == null || key.isEmpty) {
      throw FormatException(
        '[SectionImageApiResponse.fromJson] key is null or empty',
        json,
      );
    }

    return SectionImageApiResponse(
      url: url,
      key: key,
    );
  }
}

/// Section 이미지가 없을 때 발생하는 예외 (Data Layer 내부용)
///
/// Repository에서 null로 변환되어 UI 레이어로는 전파되지 않음
class SectionImageNotFoundException implements Exception {
  final String message;
  SectionImageNotFoundException(this.message);

  @override
  String toString() => message;
}

/// Section 이미지 API 호출 전용 레이어
class SectionImageApi {
  final AuthService _authService;
  final http.Client _httpClient;

  SectionImageApi({
    required AuthService authService,
    required http.Client httpClient,
  })  : _authService = authService,
        _httpClient = httpClient;

  /// Section 이미지 URL 조회
  ///
  /// API 스펙: GET /storage/section?academyUserId={id}&studentResponseId={id}&questionNumber={num}&subQuestionNumber={num}
  /// (백엔드와 합의 완료)
  Future<SectionImageApiResponse> fetchSectionImageUrl({
    required int academyUserId,
    required int studentResponseId,
    required int questionNumber,
    required int subQuestionNumber,
  }) async {
    appLog(
      '[section_image:section_image_api] API 호출 시작 - academyUserId: $academyUserId, studentResponseId: $studentResponseId, questionNumber: $questionNumber, subQuestionNumber: $subQuestionNumber',
    );

    // 1. 토큰 확인
    final token = await _authService.ensureValidAccessToken();
    if (token == null) {
      appLog('[section_image:section_image_api] 인증 토큰 없음');
      throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
    }

    // 2. URI 생성
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/storage/section?academyUserId=$academyUserId&studentResponseId=$studentResponseId&questionNumber=$questionNumber&subQuestionNumber=$subQuestionNumber',
    );

    appLog('[section_image:section_image_api] GET 요청: $uri');
    developer.log('🖼️ [SectionImageApi] GET $uri');

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
      '[section_image:section_image_api] 응답 상태 코드: ${response.statusCode}',
    );
    appLog(
      '[section_image:section_image_api] 응답 본문: ${response.body}',
    );
    developer.log(
      '🖼️ [SectionImageApi] Response status: ${response.statusCode}',
    );

    // 4. 에러 처리
    if (response.statusCode == 401) {
      appLog('[section_image:section_image_api] 인증 실패 (401)');
      throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
    }
    if (response.statusCode == 404) {
      appLog('[section_image:section_image_api] 이미지 없음 (404)');
      throw SectionImageNotFoundException('해당 문제의 이미지를 찾을 수 없습니다.');
    }
    if (response.statusCode != 200) {
      appLog(
        '[section_image:section_image_api] API 호출 실패 - status: ${response.statusCode}',
      );
      throw Exception('이미지 정보를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.');
    }

    // 5. JSON 파싱
    try {
      final Map<String, dynamic> data = json.decode(response.body);
      final result = SectionImageApiResponse.fromJson(data);

      appLog('[section_image:section_image_api] 응답 파싱 성공');
      return result;
    } catch (e) {
      appLog('[section_image:section_image_api] 응답 파싱 실패: $e');
      appLog('[section_image:section_image_api] 응답 본문: ${response.body}');
      developer.log('❌ [SectionImageApi] 응답 파싱 실패: $e');
      developer.log('❌ [SectionImageApi] Response body: ${response.body}');
      rethrow;
    }
  }
}


