import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'auth_service.dart';
import '../config/api_config.dart';
import '../utils/app_logger.dart';

class AcademyService {
  static final AcademyService _instance = AcademyService._internal();
  factory AcademyService() => _instance;
  AcademyService._internal();

  // ApiConfig에서 서버 URL 가져오기
  final AuthService _authService = AuthService();

  // SharedPreferences 키
  static const String _academiesCacheKey = 'user_academies_cache';
  static const String _defaultAcademyCodeKey = 'default_academy_code';

  // 클래스 정보 캐시 (메모리)
  final Map<String, String> _classCache = {};

  /// 디폴트 학원 변경 감지용 노티파이어
  final ValueNotifier<int> defaultAcademyVersion = ValueNotifier<int>(0);

  /// 근처 학원 리스트 조회
  Future<List<AcademyResponse>> getNearbyAcademies({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // JWT 토큰 가져오기
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
      }

      // API 엔드포인트 구성 (radius, page, size는 0으로 고정 - 백엔드에서 디폴트값 사용)
      final uri = Uri.parse(
        // '${ApiConfig.baseUrl}/academy/nearby?lat=$latitude&lng=$longitude',
        '${ApiConfig.baseUrl}/academy/nearby?lat=37.3215&lng=127.1234', // 테스트용 예시 좌표
      );

      // API 호출
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => AcademyResponse.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
      } else {
        throw Exception('학원 정보를 가져오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 사용자 등록 학원 리스트 조회
  Future<List<UserAcademyResponse>> getUserAcademies(String userId) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/academy/academy-users/$userId/academies',
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          return data.map((item) {
            try {
              return UserAcademyResponse.fromJson(item);
            } catch (e) {
              rethrow;
            }
          }).toList();
        } catch (e) {
          throw Exception('학원 정보 파싱에 실패했습니다: $e');
        }
      } else if (response.statusCode == 404) {
        // 404는 빈 배열 반환 (학원이 없는 경우)
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
      } else {
        throw Exception('학원 정보를 가져오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 학원 등록 요청
  ///
  /// 응답: status code만 확인 (200/201이면 성공)
  /// 응답 body는 파싱하지 않으며, academyId, userId를 받지 않음
  Future<void> joinAcademyRequest({
    required String academy_id,
    required int user_id,
  }) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/academy/academy-users/join/request',
      );

      final requestBody = json.encode({
        'academy': {'academy_code': academy_id},
        'user_id': user_id,
      });

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: requestBody,
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        // 성공 응답이므로 아무것도 반환하지 않음 (응답 body 파싱 불필요)
        return;
      } else if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
      } else {
        // 에러 응답 처리 (응답 body가 JSON이 아닐 수 있으므로 안전하게 처리)
        String errorMessage = '학원 등록 요청에 실패했습니다: ${response.statusCode}';

        // 요청 본문 정보를 에러 메시지에 포함
        String requestInfo = '\n전송된 데이터: $requestBody';

        if (response.body.isNotEmpty) {
          try {
            final errorBody = json.decode(response.body);
            final serverMessage =
                errorBody['message'] ??
                errorBody['error'] ??
                errorBody['detail'] ??
                response.body;
            errorMessage = '$errorMessage\n서버 응답: $serverMessage$requestInfo';
          } catch (e) {
            // JSON 파싱 실패 시 응답 body를 그대로 사용
            errorMessage = '$errorMessage\n서버 응답: ${response.body}$requestInfo';
          }
        } else {
          errorMessage = '$errorMessage$requestInfo';
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 학원 탈퇴 요청
  Future<void> leaveAcademy(int academyUserId) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/academy/academy-users/$academyUserId/leave',
      );

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        await _removeAcademyFromCache(academyUserId);
        return;
      } else if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
      } else {
        final message = response.body.isNotEmpty ? response.body : '응답 없음';
        throw Exception('학원 탈퇴 요청에 실패했습니다: $message');
      }
    } catch (e) {
      rethrow;
    }
  }

  // TODO: 백엔드에서 academyId로 학원 상세 정보를 가져오는 API가 구현 중입니다.
  // 완료 후 frontend에서도 구현 예정입니다.

  /// 학원 목록을 SharedPreferences에 저장 (사용자별)
  Future<void> saveAcademiesToCache(List<UserAcademyResponse> academies) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await _authService.getUserId();
      if (userId == null) {
        return;
      }
      final cacheKey = '${_academiesCacheKey}_$userId';
      final jsonData = json.encode(
        academies.map((academy) => academy.toJson()).toList(),
      );
      await prefs.setString(cacheKey, jsonData);
      // 구 버전 캐시 제거
      if (prefs.containsKey(_academiesCacheKey)) {
        await prefs.remove(_academiesCacheKey);
      }
    } catch (e) {
      // 캐시 저장 실패는 무시
    }
  }

  /// SharedPreferences에서 학원 목록 로드 (사용자별)
  Future<List<UserAcademyResponse>?> loadAcademiesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await _authService.getUserId();
      if (userId == null) {
        return null;
      }
      final cacheKey = '${_academiesCacheKey}_$userId';
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson == null) {
        // 구 버전 캐시 제거
        if (prefs.containsKey(_academiesCacheKey)) {
          await prefs.remove(_academiesCacheKey);
        }
        return null;
      }

      final List<dynamic> data = json.decode(cachedJson);
      return data.map((item) => UserAcademyResponse.fromJson(item)).toList();
    } catch (e) {
      return null;
    }
  }

  /// 디폴트 학원 코드를 SharedPreferences에 저장
  Future<void> saveDefaultAcademyCode(String academyCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCode = prefs.getString(_defaultAcademyCodeKey);
      if (currentCode == academyCode) {
        return;
      }

      await prefs.setString(_defaultAcademyCodeKey, academyCode);
      defaultAcademyVersion.value++;
    } catch (e) {
      // 캐시 저장 실패는 무시
    }
  }

  /// SharedPreferences에서 디폴트 학원 코드 로드
  Future<String?> getDefaultAcademyCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_defaultAcademyCodeKey);
    } catch (e) {
      return null;
    }
  }

  /// 디폴트 학원 선택 로직
  ///
  /// 선택 우선순위:
  /// 1. SharedPreferences에 저장된 마지막 선택 학원 (registerStatus == 'Y'인 경우만)
  /// 2. registerStatus == 'Y'인 첫 번째 학원
  /// 3. 없으면 null 반환
  String? selectDefaultAcademy(List<UserAcademyResponse> academies) {
    if (academies.isEmpty) {
      return null;
    }

    // 등록완료된 학원만 필터링
    final registeredAcademies = academies
        .where((academy) => academy.registerStatus == 'Y')
        .toList();

    if (registeredAcademies.isEmpty) {
      return null;
    }

    // 1. SharedPreferences에서 마지막 선택한 학원 코드 확인
    // (비동기이므로 동기적으로 처리하기 위해 Future를 사용하지 않음)
    // 대신 academies 리스트에서 직접 확인
    // 이 메서드는 나중에 getDefaultAcademyCode()와 함께 사용됨

    // 2. 등록완료된 첫 번째 학원 반환
    final firstRegistered = registeredAcademies.first;
    if (firstRegistered.academyCode != null) {
      return firstRegistered.academyCode;
    }

    return null;
  }

  /// 마지막 선택한 학원 코드와 현재 학원 목록을 비교하여 디폴트 학원 선택
  ///
  /// 이 메서드는 비동기로 SharedPreferences를 확인하고,
  /// 저장된 학원 코드가 현재 목록에 있고 등록완료 상태인지 확인
  Future<String?> selectDefaultAcademyAsync(
    List<UserAcademyResponse> academies,
  ) async {
    if (academies.isEmpty) {
      return null;
    }

    // 등록완료된 학원만 필터링
    final registeredAcademies = academies
        .where((academy) => academy.registerStatus == 'Y')
        .toList();

    if (registeredAcademies.isEmpty) {
      return null;
    }

    // 1. SharedPreferences에서 마지막 선택한 학원 코드 확인
    final savedAcademyCode = await getDefaultAcademyCode();

    if (savedAcademyCode != null) {
      // 저장된 학원 코드가 현재 목록에 있고 등록완료 상태인지 확인
      final savedAcademy = registeredAcademies.firstWhere(
        (academy) => academy.academyCode == savedAcademyCode,
        orElse: () => registeredAcademies.first,
      );

      if (savedAcademy.academyCode != null) {
        return savedAcademy.academyCode;
      }
    }

    // 2. 저장된 학원이 없거나 유효하지 않으면 등록완료된 첫 번째 학원 반환
    final firstRegistered = registeredAcademies.first;
    if (firstRegistered.academyCode != null) {
      return firstRegistered.academyCode;
    }

    return null;
  }

  /// 학원 코드로 학원 정보 조회 (캐시에서)
  Future<UserAcademyResponse?> getAcademyByCode(String academyCode) async {
    final academies = await loadAcademiesFromCache();
    if (academies == null) {
      return null;
    }

    try {
      return academies.firstWhere(
        (academy) => academy.academyCode == academyCode,
      );
    } catch (e) {
      return null;
    }
  }

  /// 클래스 정보 조회
  ///
  /// 여러 assigneeId를 받아서 academyUserId와 className 쌍을 반환합니다.
  /// assigneeId와 academyUserId는 항상 일치하므로, academyUserId를 키로 사용합니다.
  ///
  /// [assigneeIds]: 클래스 정보를 조회할 assigneeId 리스트
  ///
  /// 반환값: Map<assigneeId, className> 형태
  /// 예: {"10": "조성제 선생님 3반", "11": "조성제 선생님 3반", "12": "오세종 선생님 3반"}
  Future<Map<String, String>> getClassesByAssigneeIds(
    List<String> assigneeIds,
  ) async {
    if (assigneeIds.isEmpty) {
      return {};
    }

    // 1. 캐시에서 확인
    final uncachedIds = assigneeIds
        .where((id) => !_classCache.containsKey(id))
        .toList();

    // 2. 캐시에 없는 ID들만 API 호출
    if (uncachedIds.isNotEmpty) {
      try {
        final token = await _authService.getAccessToken();
        if (token == null) {
          throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
        }

        final uri = ApiConfig.getAcademyClassesUri(uncachedIds);

        final response = await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);

          // academyUserId == assigneeId 이므로, academyUserId를 키로 사용
          for (var item in data) {
            final academyUserId = item['academyUserId']?.toString() ?? '';
            final className = item['className']?.toString() ?? '';

            if (academyUserId.isNotEmpty && className.isNotEmpty) {
              _classCache[academyUserId] = className;
            }
          }
        } else if (response.statusCode == 401) {
          throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
        } else {
          // API 실패 시 빈 맵 반환 (에러는 throw하지 않음)
        }
      } catch (e) {
        // 에러 발생 시에도 캐시된 데이터는 반환
      }
    }

    // 3. 캐시에서 결과 반환 (요청한 모든 ID에 대해)
    final result = Map.fromEntries(
      assigneeIds.map((id) => MapEntry(id, _classCache[id] ?? '')),
    );
    return result;
  }

  /// 클래스 정보 캐시 초기화
  void clearClassCache() {
    _classCache.clear();
  }

  /// 학원 코드로 학원 정보 및 스케줄 조회
  Future<AcademyScheduleResponse> getAcademySchedule(String academyCode) async {
    appLog('[academy:academy_service] API 호출 시작 - academyCode: $academyCode');

    try {
      // ensureValidAccessToken 사용 (다른 서비스와 일관성 유지)
      final token = await _authService.ensureValidAccessToken();
      if (token == null) {
        appLog('[academy:academy_service] 인증 토큰 없음');
        throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/academy/academy-schedules/$academyCode',
      );

      appLog('[academy:academy_service] GET 요청: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      appLog('[academy:academy_service] 응답 상태 코드: ${response.statusCode}');
      appLog('[academy:academy_service] 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        appLog('[academy:academy_service] 응답 파싱 성공');
        appLog('[academy:academy_service] 파싱된 데이터: $data');

        final result = AcademyScheduleResponse.fromJson(data);
        appLog(
          '[academy:academy_service] AcademyScheduleResponse 생성 완료 - academyName: ${result.academy.academyName}, schedules 개수: ${result.schedules.length}',
        );

        return result;
      } else if (response.statusCode == 401) {
        appLog('[academy:academy_service] 인증 실패 (401)');
        throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 404) {
        appLog('[academy:academy_service] 학원 정보 없음 (404)');
        throw Exception('학원 정보를 찾을 수 없습니다.');
      } else {
        // 로그에는 상세 정보, 예외에는 일반 메시지
        appLog(
          '[academy:academy_service] API 호출 실패 - status: ${response.statusCode}',
        );
        throw Exception('학원 정보를 가져오지 못했습니다.');
      }
    } catch (e) {
      appLog('[academy:academy_service] 에러 발생: $e');
      rethrow;
    }
  }

  Future<void> _removeAcademyFromCache(int academyUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await _authService.getUserId();
      if (userId == null) return;

      final cacheKey = '${_academiesCacheKey}_$userId';
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson == null) return;

      final List<dynamic> data = json.decode(cachedJson);
      data.removeWhere((item) => item['academy_user_id'] == academyUserId);
      await prefs.setString(cacheKey, json.encode(data));
    } catch (e) {
      // 캐시 제거 실패는 무시
    }
  }

  /// 학원 이미지 리스트 조회
  ///
  /// [academyCode]: 학원 코드
  /// 반환값: AcademyImageResponse (academy_code, academy_image_urls, main_image_url)
  Future<AcademyImageResponse> getAcademyImages(String academyCode) async {
    try {
      final token = await _authService.ensureValidAccessToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/academy/images/$academyCode');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return AcademyImageResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 404) {
        throw Exception('학원 이미지를 찾을 수 없습니다.');
      } else {
        throw Exception('학원 이미지를 가져오지 못했습니다.');
      }
    } catch (e) {
      rethrow;
    }
  }
}

/// 학원 응답 모델
class AcademyResponse {
  final String academyName;
  final String academyRoadAddress;
  final double distanceKm;
  final String? academyCode; // 학원 코드

  AcademyResponse({
    required this.academyName,
    required this.academyRoadAddress,
    required this.distanceKm,
    this.academyCode,
  });

  factory AcademyResponse.fromJson(Map<String, dynamic> json) {
    return AcademyResponse(
      academyName: json['academyName'] ?? '',
      academyRoadAddress: json['academyRoadAddress'] ?? '',
      distanceKm: (json['distanceKM'] ?? json['distanceKm'] ?? 0.0).toDouble(),
      academyCode: json['academyCode']?.toString(),
    );
  }
}

/// 사용자 등록 학원 응답 모델
class UserAcademyResponse {
  // 추가 필드들 (snake_case)
  final int? academy_user_id;
  final int? academy_id;
  final int? class_id;
  final int? user_id;
  final int? learner_id;

  // 기존 필드들 (camelCase로 유지 - UI에서 사용)
  final String academyName;
  final String academyRoadAddress;
  final String registerStatus; // 'Y' 또는 'P'
  final String? academyCode; // 학원 코드

  UserAcademyResponse({
    this.academy_user_id,
    this.academy_id,
    this.class_id,
    this.user_id,
    this.learner_id,
    required this.academyName,
    required this.academyRoadAddress,
    required this.registerStatus,
    this.academyCode,
  });

  factory UserAcademyResponse.fromJson(Map<String, dynamic> json) {
    try {
      // academy 객체 추출 (null 안전)
      final academy = json['academy'] as Map<String, dynamic>? ?? {};

      final academyName = academy['academy_name']?.toString() ?? '';
      final academyCode = academy['academy_code']?.toString();
      final registerStatus = json['register_status']?.toString() ?? 'P';

      return UserAcademyResponse(
        // 추가 필드들 (snake_case)
        academy_user_id: json['academy_user_id'] as int?,
        academy_id: json['academy_id'] as int?,
        class_id: json['class_id'] as int?,
        user_id: json['user_id'] as int?,
        learner_id: json['learner_id'] as int?,

        // academy 객체에서 추출한 필드들
        academyName: academyName,
        academyRoadAddress: academy['academy_road_address']?.toString() ?? '',
        registerStatus: registerStatus,
        academyCode: academyCode,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// JSON으로 변환 (SharedPreferences 저장용)
  Map<String, dynamic> toJson() {
    return {
      'academy_user_id': academy_user_id,
      'academy_id': academy_id,
      'class_id': class_id,
      'user_id': user_id,
      'learner_id': learner_id,
      'academyName': academyName,
      'academyRoadAddress': academyRoadAddress,
      'registerStatus': registerStatus,
      'academyCode': academyCode,
    };
  }
}

/// 학원 스케줄 API 응답 모델
class AcademyScheduleResponse {
  final AcademyInfo academy;
  final List<Schedule> schedules;

  AcademyScheduleResponse({required this.academy, required this.schedules});

  factory AcademyScheduleResponse.fromJson(Map<String, dynamic> json) {
    return AcademyScheduleResponse(
      academy: AcademyInfo.fromJson(json['academy'] as Map<String, dynamic>),
      schedules:
          (json['schedules'] as List<dynamic>?)
              ?.map((item) => Schedule.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 학원 정보 DTO (API 응답 전용)
///
/// 주의: AcademyData와 중복 가능성이 있습니다.
/// 나중에 도메인 모델 통합을 고려해야 합니다.
class AcademyInfo {
  final String academyName;
  final String academyCode;
  final String academyDescription;
  final String academyPhone;
  final String academyEmail;
  final String academyWebsite;
  final String academyRoadAddress;
  final String academyDetailAddress;
  final double academyLatitude;
  final double academyLongitude;

  AcademyInfo({
    required this.academyName,
    required this.academyCode,
    required this.academyDescription,
    required this.academyPhone,
    required this.academyEmail,
    required this.academyWebsite,
    required this.academyRoadAddress,
    required this.academyDetailAddress,
    required this.academyLatitude,
    required this.academyLongitude,
  });

  factory AcademyInfo.fromJson(Map<String, dynamic> json) {
    return AcademyInfo(
      academyName: json['academy_name'] as String? ?? '',
      academyCode: json['academy_code'] as String? ?? '',
      academyDescription: json['academy_description'] as String? ?? '',
      academyPhone: json['academy_phone'] as String? ?? '',
      academyEmail: json['academy_email'] as String? ?? '',
      academyWebsite: json['academy_website'] as String? ?? '',
      academyRoadAddress: json['academy_road_address'] as String? ?? '',
      academyDetailAddress: json['academy_detail_address'] as String? ?? '',
      academyLatitude: (json['academy_latitude'] as num?)?.toDouble() ?? 0.0,
      academyLongitude: (json['academy_longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// 학원 스케줄 모델
class Schedule {
  final int id;
  final String academyCode;
  final int dayOfWeek; // 0=일요일, 1=월요일, ..., 6=토요일
  final String startTime; // "HH:MM:SS"
  final String endTime; // "HH:MM:SS"

  Schedule({
    required this.id,
    required this.academyCode,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as int? ?? 0,
      academyCode: json['academy_code'] as String? ?? '',
      dayOfWeek: json['day_of_week'] as int? ?? 0,
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
    );
  }

  /// dayOfWeek를 요일 이름으로 변환
  ///
  /// 범위 체크를 통해 0~6 외 값이 들어와도 안전하게 처리합니다.
  String get dayName {
    const days = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];
    // 범위 체크: 0~6 외 값 방어
    if (dayOfWeek < 0 || dayOfWeek > 6) {
      return '알 수 없음';
    }
    return days[dayOfWeek];
  }

  /// 시간 포맷팅 (HH:MM:SS → HH:MM AM/PM)
  ///
  /// TODO: 나중에 시간 관련 로직이 복잡해지면 DateTime/TimeOfDay로 파싱 고려
  /// TODO: 국제화 필요 시 intl 패키지 DateFormat 사용 고려
  String get formattedStartTime {
    return _formatTime(startTime);
  }

  String get formattedEndTime {
    return _formatTime(endTime);
  }

  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = parts[1];
        if (hour == 0) {
          return '12:$minute AM';
        } else if (hour < 12) {
          return '$hour:$minute AM';
        } else if (hour == 12) {
          return '12:$minute PM';
        } else {
          return '${hour - 12}:$minute PM';
        }
      }
    } catch (e) {
      // 파싱 실패 시 원본 반환
    }
    return timeStr;
  }
}

/// 학원 이미지 API 응답 모델
class AcademyImageResponse {
  final String academyCode;
  final List<String> academyImageUrls;
  final String? mainImageUrl;

  AcademyImageResponse({
    required this.academyCode,
    required this.academyImageUrls,
    this.mainImageUrl,
  });

  factory AcademyImageResponse.fromJson(Map<String, dynamic> json) {
    return AcademyImageResponse(
      academyCode: json['academy_code'] as String? ?? '',
      academyImageUrls:
          (json['academy_image_urls'] as List<dynamic>?)
              ?.map((url) => url.toString())
              .toList() ??
          [],
      mainImageUrl: json['main_image_url']?.toString(),
    );
  }
}
