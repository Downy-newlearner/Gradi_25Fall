import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

/// ⚠️ Dart 문법상 클래스는 파일 최상위에 선언
/// WorkbookApiResponse와 BookData를 파일 최상위로 이동

/// API 응답 DTO (서버 응답 구조 그대로)
///
/// API 응답은 배열 형태: [{academyUserId: 20, books: [...]}, {academyUserId: 25, books: [...]}]
class WorkbookApiResponse {
  final int academyUserId;
  final List<BookData> books;

  WorkbookApiResponse({required this.academyUserId, required this.books});

  factory WorkbookApiResponse.fromJson(Map<String, dynamic> json) {
    return WorkbookApiResponse(
      academyUserId: json['academyUserId'] as int? ?? 0,
      books:
          (json['books'] as List<dynamic>?)
              ?.map((item) => BookData.fromJson(item))
              .toList() ??
          [],
    );
  }
}

/// Book 데이터 DTO
///
/// API 응답의 books 배열 내부 객체 구조
class BookData {
  final int? bookId; // book_id
  final String? bookName; // book_name
  final int bookPage; // book_page
  final String? bookSemester; // book_semester
  final String? bookImageUrl; // book_image_url
  final int totalSolvedPages; // total_solved_pages
  final String? latestUpdatedAt; // latest_updated_at

  BookData({
    this.bookId,
    this.bookName,
    required this.bookPage,
    this.bookSemester,
    this.bookImageUrl,
    required this.totalSolvedPages,
    this.latestUpdatedAt,
  });

  factory BookData.fromJson(Map<String, dynamic> json) {
    return BookData(
      bookId: json['book_id'] as int?,
      bookName: json['book_name'] as String?,
      bookPage: json['book_page'] as int? ?? 0,
      bookSemester: json['book_semester'] as String?,
      bookImageUrl: json['book_image_url'] as String?,
      totalSolvedPages: json['total_solved_pages'] as int? ?? 0,
      latestUpdatedAt: json['latest_updated_at'] as String?,
    );
  }
}

/// Workbook API 호출 전용 레이어
class WorkbookApi {
  WorkbookApi({AuthService? authService, http.Client? httpClient})
    : _authService = authService ?? AuthService(),
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  /// 여러 academyUserId에 대한 문제집 조회 (한 번에)
  ///
  /// 여러 academyUserId를 콤마로 구분해서 한 번에 조회합니다.
  /// 예: academyUserId=20,25
  ///
  /// [academyUserIds]: 조회할 academyUserId 리스트
  ///
  /// 반환값: 각 academyUserId별 WorkbookApiResponse 리스트
  Future<List<WorkbookApiResponse>> fetchWorkbooks(
    List<int> academyUserIds,
  ) async {
    final token = await _authService.ensureValidAccessToken();
    if (token == null) {
      throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
    }

    // academyUserIds를 콤마로 구분한 문자열로 변환
    final idsParam = academyUserIds.join(',');
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/grading/student-responses/workbook?academyUserIds=$idsParam',
    );

    developer.log('📚 [WorkbookApi] GET $uri');

    final response = await _httpClient
        .get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    developer.log('📚 [WorkbookApi] Response status: ${response.statusCode}');

    if (response.statusCode == 401) {
      throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
    }
    if (response.statusCode != 200) {
      throw Exception('Workbook API 호출 실패 (status: ${response.statusCode})');
    }

    try {
      final List<dynamic> data = json.decode(response.body);

      // API 응답은 배열: [{academyUserId: 20, books: [...]}, {academyUserId: 25, books: [...]}]
      final result = data
          .map(
            (item) =>
                WorkbookApiResponse.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      return result;
    } catch (e) {
      developer.log('❌ [WorkbookApi] 응답 파싱 실패: $e');
      developer.log('❌ [WorkbookApi] Response body: ${response.body}');
      rethrow;
    }
  }
}
