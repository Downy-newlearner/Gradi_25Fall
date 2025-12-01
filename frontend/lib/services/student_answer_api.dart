import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/app_logger.dart';
import 'auth_service.dart';

/// API 응답 DTO (서버 응답 구조 그대로)
class StudentAnswerApiResponse {
  final int studentAnswerId;
  final int studentResponseId;
  final int? chapterId;
  final int page;
  final int questionNumber;
  final int subQuestionNumber;
  final String answer; // 문자열
  final String? sectionUrl;
  final bool? isCorrect; // null = 답안 없음, true = 맞음, false = 틀림
  final double score;

  StudentAnswerApiResponse({
    required this.studentAnswerId,
    required this.studentResponseId,
    this.chapterId,
    required this.page,
    required this.questionNumber,
    required this.subQuestionNumber,
    required this.answer,
    this.sectionUrl,
    required this.isCorrect,
    required this.score,
  });

  factory StudentAnswerApiResponse.fromJson(Map<String, dynamic> json) {
    // 필수 필드 검증 (ID는 0이면 유효하지 않음)
    final studentAnswerId = json['student_answer_id'] as int?;
    final studentResponseId = json['student_response_id'] as int?;

    if (studentAnswerId == null || studentAnswerId == 0) {
      throw FormatException(
        '[StudentAnswerApiResponse.fromJson] student_answer_id is null or 0',
        json,
      );
    }
    if (studentResponseId == null || studentResponseId == 0) {
      throw FormatException(
        '[StudentAnswerApiResponse.fromJson] student_response_id is null or 0',
        json,
      );
    }

    return StudentAnswerApiResponse(
      studentAnswerId: studentAnswerId,
      studentResponseId: studentResponseId,
      chapterId: json['chapter_id'] as int?,
      page: json['page'] as int? ?? 0,
      questionNumber: json['question_number'] as int? ?? 0,
      subQuestionNumber: json['sub_question_number'] as int? ?? 0,
      answer: json['answer'] as String? ?? '', // null이면 빈 문자열
      sectionUrl: json['section_url'] as String?,
      isCorrect: json['is_correct'] as bool?, // null 허용
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Student Answer API 호출 전용 레이어
class StudentAnswerApi {
  final AuthService _authService;
  final http.Client _httpClient;

  StudentAnswerApi({AuthService? authService, http.Client? httpClient})
    : _authService = authService ?? AuthService(),
      _httpClient = httpClient ?? http.Client();

  /// studentResponseId로 학생 답안 목록 조회
  ///
  /// API 스펙: GET /grading/student-answers/response?student_response_id={id}
  /// (백엔드와 합의 완료)
  Future<List<StudentAnswerApiResponse>> fetchStudentAnswers(
    int studentResponseId,
  ) async {
    appLog(
      '[student_answer:student_answer_api] API 호출 시작 - studentResponseId: $studentResponseId',
    );

    // 1. 토큰 확인
    final token = await _authService.ensureValidAccessToken();
    if (token == null) {
      appLog('[student_answer:student_answer_api] 인증 토큰 없음');
      throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
    }

    // 2. URI 생성
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/grading/student-answers/response?student_response_id=$studentResponseId',
    );

    appLog('[student_answer:student_answer_api] GET 요청: $uri');
    developer.log('📝 [StudentAnswerApi] GET $uri');

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
      '[student_answer:student_answer_api] 응답 상태 코드: ${response.statusCode}',
    );
    developer.log(
      '📝 [StudentAnswerApi] Response status: ${response.statusCode}',
    );

    // 4. 에러 처리
    if (response.statusCode == 401) {
      appLog('[student_answer:student_answer_api] 인증 실패 (401)');
      throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
    }
    if (response.statusCode != 200) {
      appLog(
        '[student_answer:student_answer_api] API 호출 실패 - status: ${response.statusCode}',
      );
      throw Exception('학생 답안 조회에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }

    // 5. JSON 파싱
    try {
      final List<dynamic> data = json.decode(response.body);
      final result = data
          .map(
            (item) =>
                StudentAnswerApiResponse.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      appLog(
        '[student_answer:student_answer_api] 응답 파싱 성공 - 항목 수: ${result.length}',
      );
      appLog('[student_answer:student_answer_api] 응답 본문: ${response.body}');
      return result;
    } catch (e) {
      appLog('[student_answer:student_answer_api] 응답 파싱 실패: $e');
      appLog('[student_answer:student_answer_api] 응답 본문: ${response.body}');
      developer.log('❌ [StudentAnswerApi] 응답 파싱 실패: $e');
      developer.log('❌ [StudentAnswerApi] Response body: ${response.body}');
      rethrow;
    }
  }

  /// 수정된 답안들을 서버에 저장
  ///
  /// API 스펙: PATCH /grading/student-answers (추정, 백엔드 확인 필요)
  /// Payload: [{student_answer_id: 1, answer: "B"}, ...]
  Future<void> updateStudentAnswers(List<Map<String, dynamic>> payload) async {
    appLog(
      '[student_answer:student_answer_api] 답안 수정 API 호출 시작 - 수정 항목 수: ${payload.length}',
    );

    // 1. 토큰 확인
    final token = await _authService.ensureValidAccessToken();
    if (token == null) {
      throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
    }

    // 2. URI 생성 (백엔드 스펙 확인 필요)
    final uri = Uri.parse('${ApiConfig.baseUrl}/grading/student-answers');

    appLog('[student_answer:student_answer_api] PATCH 요청: $uri');
    developer.log('📝 [StudentAnswerApi] PATCH $uri');

    // 3. API 호출
    final response = await _httpClient
        .patch(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(payload),
        )
        .timeout(const Duration(seconds: 10));

    appLog(
      '[student_answer:student_answer_api] 응답 상태 코드: ${response.statusCode}',
    );

    // 4. 에러 처리
    if (response.statusCode == 401) {
      throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
    }
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('답안 저장에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }

    appLog('[student_answer:student_answer_api] 답안 수정 성공');
  }

  /// chapterId + academyUserId로 학생 답안 조회 (grass API)
  ///
  /// **API 스펙**: GET /grading/student-answers/grass?academyUserId={id}&chapterId={id}
  ///
  /// **응답 구조**:
  /// - is_correct가 null이면 안 푼 문제
  /// - is_correct가 true면 맞은 문제
  /// - is_correct가 false면 틀린 문제
  Future<List<StudentAnswerApiResponse>> fetchStudentAnswersByChapterAndAcademy(
    int chapterId,
    int academyUserId,
  ) async {
    appLog(
      '[student_answer:student_answer_api] Grass API 호출 시작 - chapterId: $chapterId, academyUserId: $academyUserId',
    );

    // 1. 토큰 확인
    final token = await _authService.ensureValidAccessToken();
    if (token == null) {
      appLog('[student_answer:student_answer_api] 인증 토큰 없음');
      throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
    }

    // 2. URI 생성
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/grading/student-answers/grass?academyUserId=$academyUserId&chapterId=$chapterId',
    );

    appLog('[student_answer:student_answer_api] GET 요청: $uri');
    developer.log('📝 [StudentAnswerApi] GET $uri');

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
      '[student_answer:student_answer_api] 응답 상태 코드: ${response.statusCode}',
    );
    developer.log(
      '📝 [StudentAnswerApi] Response status: ${response.statusCode}',
    );

    // 4. 에러 처리
    if (response.statusCode == 401) {
      appLog('[student_answer:student_answer_api] 인증 실패 (401)');
      throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
    }
    if (response.statusCode != 200) {
      appLog(
        '[student_answer:student_answer_api] API 호출 실패 - status: ${response.statusCode}',
      );
      throw Exception('학생 답안 조회에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }

    // 5. JSON 파싱
    try {
      final List<dynamic> data = json.decode(response.body);
      final result = data
          .map(
            (item) =>
                StudentAnswerApiResponse.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      appLog(
        '[student_answer:student_answer_api] 응답 파싱 성공 - 항목 수: ${result.length}',
      );
      appLog('[student_answer:student_answer_api] 응답 본문: ${response.body}');
      return result;
    } catch (e) {
      appLog('[student_answer:student_answer_api] 응답 파싱 실패: $e');
      appLog('[student_answer:student_answer_api] 응답 본문: ${response.body}');
      developer.log('❌ [StudentAnswerApi] 응답 파싱 실패: $e');
      developer.log('❌ [StudentAnswerApi] Response body: ${response.body}');
      rethrow;
    }
  }
}
