import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'auth_service.dart';
import '../config/api_config.dart';

class AcademyService {
  static final AcademyService _instance = AcademyService._internal();
  factory AcademyService() => _instance;
  AcademyService._internal();

  // ApiConfig에서 서버 URL 가져오기
  final AuthService _authService = AuthService();

  /// 근처 학원 리스트 조회
  Future<List<AcademyResponse>> getNearbyAcademies({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // JWT 토큰 가져오기
      final token = await _authService.getAccessToken();
      if (token == null) {
        developer.log('No access token available');
        throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
      }

      // API 엔드포인트 구성 (radius, page, size는 0으로 고정 - 백엔드에서 디폴트값 사용)
      final uri = Uri.parse(
        // '${ApiConfig.baseUrl}/academy/nearby?lat=$latitude&lng=$longitude',
        '${ApiConfig.baseUrl}/academy/nearby?lat=37.3215&lng=127.1234', // 테스트용 예시 좌표
      );

      developer.log('Fetching nearby academies from: $uri');

      // API 호출
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => AcademyResponse.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
      } else {
        throw Exception('학원 정보를 가져오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching nearby academies: $e');
      rethrow;
    }
  }

  /// 사용자 등록 학원 리스트 조회
  Future<List<UserAcademyResponse>> getUserAcademies(String userId) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        developer.log('No access token available');
        throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/academy/academy-users/$userId/academies',
      );
      developer.log('Fetching user academies from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => UserAcademyResponse.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
      } else {
        throw Exception('학원 정보를 가져오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching user academies: $e');
      rethrow;
    }
  }

  /// 학원 등록 요청
  ///
  /// [2025.11.12]
  /// - class_id: 어떤 반인지 (반 정보)
  /// - learner_id: 학번 (학원에서 학번을 제공하는 경우 사용할 예정)
  Future<void> joinAcademyRequest({
    required int academyId,
    required int classId,
    required int userId,
    required int learnerId,
  }) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        developer.log('No access token available');
        throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/academy/academy-users/join/request',
      );
      developer.log('Sending academy join request to: $uri');

      final requestBody = json.encode({
        'academy_id': academyId,
        'class_id': classId,
        'user_id': userId,
        'learner_id': learnerId,
      });

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: requestBody,
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        developer.log('Academy join request successful');
      } else if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage =
            errorBody['message'] ??
            errorBody['error'] ??
            '학원 등록 요청에 실패했습니다: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log('Error joining academy: $e');
      rethrow;
    }
  }

  // TODO: 백엔드에서 academyId로 학원 상세 정보를 가져오는 API가 구현 중입니다.
  // 완료 후 frontend에서도 구현 예정입니다.
}

/// 학원 응답 모델
class AcademyResponse {
  final String academyName;
  final String academyRoadAddress;
  final double distanceKm;
  final int? academyId; // 학원 ID

  AcademyResponse({
    required this.academyName,
    required this.academyRoadAddress,
    required this.distanceKm,
    this.academyId,
  });

  factory AcademyResponse.fromJson(Map<String, dynamic> json) {
    return AcademyResponse(
      academyName: json['academyName'] ?? '',
      academyRoadAddress: json['academyRoadAddress'] ?? '',
      distanceKm: (json['distanceKM'] ?? json['distanceKm'] ?? 0.0).toDouble(),
      academyId: json['academyId'] != null
          ? (json['academyId'] is int
                ? json['academyId']
                : int.tryParse(json['academyId'].toString()))
          : null,
    );
  }
}

/// 사용자 등록 학원 응답 모델
class UserAcademyResponse {
  final String academyName;
  final String academyRoadAddress;
  final String registerStatus; // 'Y' 또는 'P'

  UserAcademyResponse({
    required this.academyName,
    required this.academyRoadAddress,
    required this.registerStatus,
  });

  factory UserAcademyResponse.fromJson(Map<String, dynamic> json) {
    return UserAcademyResponse(
      academyName: json['academyName'] ?? '',
      academyRoadAddress: json['academyRoadAddress'] ?? '',
      registerStatus: json['registerStatus'] ?? 'P',
    );
  }
}
