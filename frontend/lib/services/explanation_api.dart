import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../utils/app_logger.dart';

/// 해설 생성/조회용 API 래퍼
class ExplanationApi {
  final Future<String?> Function() _tokenProvider;
  final http.Client _httpClient;

  ExplanationApi({
    required Future<String?> Function() tokenProvider,
    required http.Client httpClient,
  }) : _tokenProvider = tokenProvider,
       _httpClient = httpClient;

  /// 해설 생성 요청
  ///
  /// POST /grading/student-answers/explanation
  /// Body:
  /// {
  ///   "student_response_id": ...,
  ///   "user_id": ...,
  ///   "academy_user_id": ...,
  ///   "academy_id": ...,
  ///   "page_number": ...,
  ///   "question_number": ...,
  ///   "answer": ...
  /// }
  Future<Map<String, dynamic>> postExplanation({
    required int studentResponseId,
    required int userId,
    required int academyUserId,
    required int academyId,
    required int pageNumber,
    required int questionNumber,
    required String answer,
  }) async {
    final token = await _tokenProvider();
    if (token == null) {
      throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/grading/student-answers/explanation',
    );

    final body = <String, dynamic>{
      'student_response_id': studentResponseId,
      'user_id': userId,
      'academy_user_id': academyUserId,
      'academy_id': academyId,
      'page_number': pageNumber,
      'question_number': questionNumber,
      'answer': answer,
    };

    appLog('[explanation] POST INPUT: $uri');
    appLog('[explanation] POST INPUT body: ${json.encode(body)}');

    final response = await _httpClient
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(body),
        )
        .timeout(const Duration(seconds: 15));

    appLog('[explanation] POST OUTPUT status: ${response.statusCode}');

    if (response.statusCode == 401) {
      throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
    }
    if (response.statusCode != 200) {
      appLog('[explanation] POST OUTPUT error body: ${response.body}');
      throw Exception('해설 생성 요청에 실패했습니다. (status: ${response.statusCode})');
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    appLog('[explanation] POST OUTPUT body: ${json.encode(decoded)}');
    return decoded;
  }

  /// 학생 답안 정보 조회
  ///
  /// GET /grading/student-answers/find
  ///   ?studentResponseId={id}
  ///   &questionNumber={n}
  ///   &subQuestionNumber={n}
  Future<Map<String, dynamic>> findStudentAnswer({
    required int studentResponseId,
    required int questionNumber,
    required int subQuestionNumber,
  }) async {
    final token = await _tokenProvider();
    if (token == null) {
      throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/grading/student-answers/find'
      '?studentResponseId=$studentResponseId'
      '&questionNumber=$questionNumber'
      '&subQuestionNumber=$subQuestionNumber',
    );

    appLog('[explanation] GET (정답 가져오기) INPUT: $uri');
    appLog(
      '[explanation] GET (정답 가져오기) INPUT params: studentResponseId=$studentResponseId, questionNumber=$questionNumber, subQuestionNumber=$subQuestionNumber',
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

    appLog('[explanation] GET (정답 가져오기) OUTPUT status: ${response.statusCode}');

    if (response.statusCode == 401) {
      throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
    }
    if (response.statusCode != 200) {
      appLog('[explanation] GET (정답 가져오기) OUTPUT error body: ${response.body}');
      throw Exception('학생 답안 조회에 실패했습니다. (status: ${response.statusCode})');
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    appLog('[explanation] GET (정답 가져오기) OUTPUT body: ${json.encode(decoded)}');
    return decoded;
  }

  /// 해설 조회 (Redis에서 LLM 해설 가져오기)
  ///
  /// GET /grading/student-answers/get-explanation
  ///   ?studentResponseId={id}
  ///   &academyUserId={id}
  ///   &questionNumber={n}
  ///   &subquestionNumber={n}
  ///
  /// 404와 400 응답은 동일하게 처리하여 null을 반환합니다.
  /// (해설이 아직 생성되지 않았거나 Redis에 없음을 의미)
  Future<Map<String, dynamic>?> getExplanation({
    required int studentResponseId,
    required int academyUserId,
    required int questionNumber,
    required int subQuestionNumber,
  }) async {
    final token = await _tokenProvider();
    if (token == null) {
      throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/grading/student-answers/get-explanation'
      '?studentResponseId=$studentResponseId'
      '&academyUserId=$academyUserId'
      '&questionNumber=$questionNumber'
      '&subQuestionNumber=$subQuestionNumber',
    );

    appLog('[explanation] GET (Redis에서 LLM 해설 가져오기) INPUT: $uri');
    appLog(
      '[explanation] GET (Redis에서 LLM 해설 가져오기) INPUT params: studentResponseId=$studentResponseId, academyUserId=$academyUserId, questionNumber=$questionNumber, subQuestionNumber=$subQuestionNumber',
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

    appLog(
      '[explanation] GET (Redis에서 LLM 해설 가져오기) OUTPUT status: ${response.statusCode}',
    );

    // 404와 400을 동일하게 처리: 해설이 아직 생성되지 않았거나 Redis에 없음
    if (response.statusCode == 404 || response.statusCode == 400) {
      appLog(
        '[explanation] GET (Redis에서 LLM 해설 가져오기) OUTPUT: 해설이 아직 생성되지 않았거나 Redis에 없음 (404/400)',
      );
      appLog('[explanation] GET (Redis에서 LLM 해설 가져오기) OUTPUT body: null');
      return null;
    }
    if (response.statusCode == 401) {
      appLog('[explanation] GET (Redis에서 LLM 해설 가져오기) OUTPUT error: 인증 실패');
      throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
    }
    if (response.statusCode != 200) {
      appLog(
        '[explanation] GET (Redis에서 LLM 해설 가져오기) OUTPUT error body: ${response.body}',
      );
      throw Exception('해설 조회에 실패했습니다. (status: ${response.statusCode})');
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    appLog(
      '[explanation] GET (Redis에서 LLM 해설 가져오기) OUTPUT body: ${json.encode(decoded)}',
    );
    return decoded;
  }
}
