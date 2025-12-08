import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';
import '../utils/api_date_formatter.dart';
import '../utils/app_logger.dart';

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
  WorkbookApi({
    required AuthService authService,
    required http.Client httpClient,
  })  : _authService = authService,
        _httpClient = httpClient;

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

  /// 날짜 범위로 문제집 학습 현황 조회
  ///
  /// **중요: 날짜 및 타임존 규약**
  /// - startDate와 endDate는 KST(UTC+9) 기준으로 해석됩니다.
  /// - 입력 DateTime은 반드시 UTC 기반이어야 하며, 이미 KST로 변환된 상태여야 합니다.
  /// - API 요청 시 ISO8601 문자열에 timezone 정보(+09:00)가 포함됩니다.
  /// - 서버는 이 timezone 정보를 기반으로 KST 기준으로 데이터를 조회합니다.
  ///
  /// **예시:**
  /// - startDate: DateTime.utc(2025, 11, 1) (KST 기준 2025-11-01을 의미)
  /// - 요청 파라미터: "2025-11-01T00:00:00+09:00"
  /// - 서버는 KST 기준 2025-11-01 00:00:00 ~ 23:59:59 범위의 데이터를 조회합니다.
  ///
  /// [academyUserIds]: 조회할 academyUserId 리스트 (비어있으면 안됨)
  /// [startDate]: 시작 날짜 (KST 기준, UTC 기반 DateTime, 시간 정보 무시)
  /// [endDate]: 종료 날짜 (KST 기준, UTC 기반 DateTime, 시간 정보 무시)
  ///
  /// 반환값: 각 academyUserId별 WorkbookApiResponse 리스트
  /// 
  /// 예외:
  /// - ArgumentError: startDate > endDate 또는 academyUserIds가 비어있을 때
  /// - Exception: API 호출 실패 시
  Future<List<WorkbookApiResponse>> fetchWorkbooksByDateRange({
    required List<int> academyUserIds,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Validation
    if (academyUserIds.isEmpty) {
      throw ArgumentError('academyUserIds는 비어있을 수 없습니다.');
    }

    // 날짜 비교 (시간 정보 무시)
    final startDateOnly = DateTime.utc(startDate.year, startDate.month, startDate.day);
    final endDateOnly = DateTime.utc(endDate.year, endDate.month, endDate.day);

    if (startDateOnly.isAfter(endDateOnly)) {
      throw ArgumentError('startDate는 endDate보다 이전이어야 합니다.');
    }

    final token = await _authService.ensureValidAccessToken();
    if (token == null) {
      throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
    }

    // KST 기준 ISO8601 문자열 생성 (timezone 포함)
    // 중요: startDate와 endDate는 이미 KST로 변환된 상태이므로
    // ApiDateFormatter가 UTC 기반으로 올바르게 변환합니다.
    final startIso = ApiDateFormatter.formatDayStart(startDateOnly);
    final endIso = ApiDateFormatter.formatDayEnd(endDateOnly);

    // academyUserIds를 콤마로 구분한 문자열로 변환
    final idsParam = academyUserIds.join(',');

    // URI 생성
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/grading/student-responses/workbook/range'
      '?academyUserIds=$idsParam'
      '&startDate=${Uri.encodeComponent(startIso)}'
      '&endDate=${Uri.encodeComponent(endIso)}',
    );

    developer.log('📚 [WorkbookApi] GET $uri');
    developer.log('📚 [WorkbookApi] startDate: $startIso, endDate: $endIso');
    appLog('[workbook:workbook_api] API 호출 시작');
    appLog('[workbook:workbook_api] GET 요청: $uri');
    appLog('[workbook:workbook_api] academyUserIds: $idsParam');
    appLog('[workbook:workbook_api] startDate: $startIso');
    appLog('[workbook:workbook_api] endDate: $endIso');

    http.Response? response;
    String? responseBody;
    
    try {
      response = await _httpClient
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      developer.log('📚 [WorkbookApi] Response status: ${response.statusCode}');

      // 상태 코드별 처리
      if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
      }
      if (response.statusCode == 400) {
        throw Exception('잘못된 요청입니다. 날짜 범위를 확인해주세요.');
      }
      if (response.statusCode == 404) {
        throw Exception('요청한 리소스를 찾을 수 없습니다.');
      }
      if (response.statusCode == 204) {
        return [];
      }
      if (response.statusCode != 200) {
        throw Exception('Workbook API 호출 실패 (status: ${response.statusCode})');
      }

      // JSON 파싱
      responseBody = response.body;
      if (responseBody.isEmpty) {
        return [];
      }

      final dynamic decoded = json.decode(responseBody);
      
      if (decoded is! List) {
        developer.log('❌ [WorkbookApi] 응답이 배열이 아닙니다: ${decoded.runtimeType}');
        throw Exception('서버 응답 형식이 올바르지 않습니다.');
      }

      final List<dynamic> data = decoded;

      // 응답 구조 로그 출력
      appLog('[workbook:workbook_api] 응답 구조:');
      appLog('[workbook:workbook_api] 응답 항목 수: ${data.length}');
      for (var i = 0; i < data.length; i++) {
        final item = data[i];
        if (item is Map<String, dynamic>) {
          appLog('[workbook:workbook_api] [항목 ${i + 1}]');
          appLog('[workbook:workbook_api]   - academyUserId: ${item['academyUserId']}');
          if (item['books'] != null && item['books'] is List) {
            final books = item['books'] as List;
            appLog('[workbook:workbook_api]   - books 개수: ${books.length}');
            for (var j = 0; j < books.length; j++) {
              final book = books[j];
              if (book is Map<String, dynamic>) {
                appLog('[workbook:workbook_api]   [책 ${j + 1}]');
                appLog('[workbook:workbook_api]     - book_id: ${book['book_id']}');
                appLog('[workbook:workbook_api]     - book_name: ${book['book_name']}');
                appLog('[workbook:workbook_api]     - book_page: ${book['book_page']}');
                appLog('[workbook:workbook_api]     - book_semester: ${book['book_semester']}');
                appLog('[workbook:workbook_api]     - book_image_url: ${book['book_image_url']}');
                appLog('[workbook:workbook_api]     - total_solved_pages: ${book['total_solved_pages']}');
                appLog('[workbook:workbook_api]     - latest_updated_at: ${book['latest_updated_at']}');
              }
            }
          } else {
            appLog('[workbook:workbook_api]   - books: null 또는 배열이 아님');
          }
        }
      }

      final result = data
          .map(
            (item) {
              if (item is! Map<String, dynamic>) {
                throw Exception('응답 항목이 올바른 형식이 아닙니다.');
              }
              return WorkbookApiResponse.fromJson(item);
            },
          )
          .toList();

      developer.log('📚 [WorkbookApi] 파싱 성공: ${result.length}개 항목');
      appLog('[workbook:workbook_api] 파싱 성공: ${result.length}개 항목');
      return result;
    } on TimeoutException {
      developer.log('❌ [WorkbookApi] 요청 시간 초과');
      throw Exception('요청 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.');
    } on FormatException catch (e) {
      developer.log('❌ [WorkbookApi] JSON 파싱 실패: $e');
      if (responseBody != null) {
        developer.log('❌ [WorkbookApi] Response body: $responseBody');
      }
      throw Exception('서버 응답을 파싱하는데 실패했습니다.');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      developer.log('❌ [WorkbookApi] 예상치 못한 오류: $e');
      throw Exception('알 수 없는 오류가 발생했습니다.');
    }
  }
}
