import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../../utils/app_logger.dart';

/// 챕터 API 응답 DTO
///
/// 서버 응답 구조를 그대로 반영합니다.
class ChapterApiResponse {
  final int chapterId;
  final int bookId;
  final int mainChapterNumber;
  final int subChapterNumber;
  final String? chapterName;
  final int chapterStartPage;
  final int chapterEndPage;
  final int chapterStartQuestion;
  final int chapterEndQuestion;
  final int totalChapterQuestion;
  final int studentAnswerCount;

  ChapterApiResponse({
    required this.chapterId,
    required this.bookId,
    required this.mainChapterNumber,
    required this.subChapterNumber,
    this.chapterName,
    required this.chapterStartPage,
    required this.chapterEndPage,
    required this.chapterStartQuestion,
    required this.chapterEndQuestion,
    required this.totalChapterQuestion,
    required this.studentAnswerCount,
  });

  factory ChapterApiResponse.fromJson(Map<String, dynamic> json) {
    // 안전한 int 변환 헬퍼 함수
    int _toInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
      return defaultValue;
    }

    // 필수 필드: null이면 예외 발생 (버그 조기 발견)
    final chapterId = json['chapter_id'];
    final bookId = json['book_id'];

    if (chapterId == null || bookId == null) {
      throw FormatException(
        'ChapterApiResponse: chapter_id or book_id is null',
        jsonEncode(json),
      );
    }

    // count/번호 필드는 0 기본값 허용
    return ChapterApiResponse(
      chapterId: _toInt(chapterId),
      bookId: _toInt(bookId),
      mainChapterNumber: _toInt(json['main_chapter_number']),
      subChapterNumber: _toInt(json['sub_chapter_number']),
      chapterName: json['chapter_name'] as String?,
      chapterStartPage: _toInt(json['chapter_start_page']),
      chapterEndPage: _toInt(json['chapter_end_page']),
      chapterStartQuestion: _toInt(json['chapter_start_question']),
      chapterEndQuestion: _toInt(json['chapter_end_question']),
      // 하위 호환성: total_chapter_question이 없으면 total_chapter_problem 사용
      totalChapterQuestion: _toInt(
        json['total_chapter_question'] ?? json['total_chapter_problem'],
      ),
      studentAnswerCount: _toInt(json['student_answer_count']),
    );
  }
}

/// 챕터 API 호출 전용 레이어
class ChapterApi {
  ChapterApi({AuthService? authService, http.Client? httpClient})
    : _authService = authService ?? AuthService(),
        _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  /// 챕터 목록 조회
  ///
  /// **API 스펙**:
  /// - Method: GET
  /// - Endpoint: `/grading/chapter/book/{book_id}/user/{academy_user_id}`
  /// - Headers: `Authorization: Bearer {token}`
  ///
  /// [bookId]: 문제집 ID
  /// [academyUserId]: 학원 사용자 ID
  ///
  /// 반환: 챕터 API 응답 리스트
  Future<List<ChapterApiResponse>> fetchChapters(
    int bookId,
    int academyUserId,
  ) async {
    appLog(
      '📖 [ChapterApi] 챕터 목록 조회 시작 - bookId: $bookId, academyUserId: $academyUserId',
    );

    final token = await _authService.ensureValidAccessToken();
    if (token == null) {
      appLog('❌ [ChapterApi] 인증 토큰이 없습니다.');
      throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/grading/chapter/book/$bookId/user/$academyUserId',
    );

    appLog('📖 [ChapterApi] GET $uri');
    developer.log('📖 [ChapterApi] GET $uri');

    final response = await _httpClient
        .get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    appLog('📖 [ChapterApi] Response status: ${response.statusCode}');
    developer.log('📖 [ChapterApi] Response status: ${response.statusCode}');

    if (response.statusCode == 401) {
      appLog('❌ [ChapterApi] 인증 실패 (401)');
      throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
    }
    if (response.statusCode != 200) {
      appLog('❌ [ChapterApi] API 호출 실패 (status: ${response.statusCode})');
      throw Exception('Chapter API 호출 실패 (status: ${response.statusCode})');
    }

    try {
      final List<dynamic> data = json.decode(response.body);
      appLog('📖 [ChapterApi] 응답 파싱 성공 - 챕터 개수: ${data.length}');

      final result = data
          .map(
            (item) => ChapterApiResponse.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      // 응답 구조 전체 로그 출력
      appLog('📖 [ChapterApi] 응답 구조:');
      for (var i = 0; i < result.length; i++) {
        final chapter = result[i];
        appLog('  [챕터 ${i + 1}]');
        appLog('    - chapterId: ${chapter.chapterId}');
        appLog('    - bookId: ${chapter.bookId}');
        appLog('    - mainChapterNumber: ${chapter.mainChapterNumber}');
        appLog('    - subChapterNumber: ${chapter.subChapterNumber}');
        appLog('    - chapterName: ${chapter.chapterName ?? "null"}');
        appLog('    - chapterStartPage: ${chapter.chapterStartPage}');
        appLog('    - chapterEndPage: ${chapter.chapterEndPage}');
        appLog('    - chapterStartQuestion: ${chapter.chapterStartQuestion}');
        appLog('    - chapterEndQuestion: ${chapter.chapterEndQuestion}');
        appLog('    - totalChapterQuestion: ${chapter.totalChapterQuestion}');
        appLog('    - studentAnswerCount: ${chapter.studentAnswerCount}');
      }

      return result;
    } catch (e) {
      appLog('❌ [ChapterApi] 응답 파싱 실패: $e');
      appLog('❌ [ChapterApi] Response body: ${response.body}');
      developer.log('❌ [ChapterApi] 응답 파싱 실패: $e');
      developer.log('❌ [ChapterApi] Response body: ${response.body}');
      rethrow;
    }
  }

  /// chapterId로 단일 챕터 정보 조회
  ///
  /// **API 스펙**:
  /// - Method: GET
  /// - Endpoint: `/grading/chapter/{chapter_id}`
  /// - Headers: `Authorization: Bearer {token}`
  ///
  /// [chapterId]: 챕터 ID
  ///
  /// 반환: 챕터 API 응답
  Future<ChapterApiResponse> fetchChapterById(int chapterId) async {
    appLog('📖 [ChapterApi] 챕터 조회 시작 - chapterId: $chapterId');

    final token = await _authService.ensureValidAccessToken();
    if (token == null) {
      appLog('❌ [ChapterApi] 인증 토큰이 없습니다.');
      throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/grading/chapter/$chapterId');

    appLog('📖 [ChapterApi] GET $uri');
    developer.log('📖 [ChapterApi] GET $uri');

    final response = await _httpClient
        .get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    appLog('📖 [ChapterApi] Response status: ${response.statusCode}');
    developer.log('📖 [ChapterApi] Response status: ${response.statusCode}');

    if (response.statusCode == 401) {
      appLog('❌ [ChapterApi] 인증 실패 (401)');
      throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
    }
    if (response.statusCode != 200) {
      appLog('❌ [ChapterApi] API 호출 실패 (status: ${response.statusCode})');
      throw Exception('Chapter API 호출 실패 (status: ${response.statusCode})');
    }

    try {
      final Map<String, dynamic> data = json.decode(response.body);
      appLog('📖 [ChapterApi] 응답 파싱 성공');

      return ChapterApiResponse.fromJson(data);
    } catch (e) {
      appLog('❌ [ChapterApi] 응답 파싱 실패: $e');
      appLog('❌ [ChapterApi] Response body: ${response.body}');
      developer.log('❌ [ChapterApi] 응답 파싱 실패: $e');
      developer.log('❌ [ChapterApi] Response body: ${response.body}');
      rethrow;
    }
  }
}
