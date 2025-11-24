import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

  // SharedPreferences 키
  static const String _academiesCacheKey = 'user_academies_cache';
  static const String _defaultAcademyCodeKey = 'default_academy_code';

  // 클래스 정보 캐시 (메모리)
  final Map<String, String> _classCache = {};

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
      developer.log('🔵 [AcademyService] Fetching user academies from: $uri');
      developer.log(
        '🔵 [AcademyService] userId 타입: ${userId.runtimeType}, 값: $userId',
      );

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
        try {
          final List<dynamic> data = json.decode(response.body);
          developer.log('✅ Parsed ${data.length} academies');
          return data.map((item) {
            try {
              return UserAcademyResponse.fromJson(item);
            } catch (e) {
              developer.log('❌ Error parsing academy item: $e');
              developer.log('❌ Item data: $item');
              rethrow;
            }
          }).toList();
        } catch (e) {
          developer.log('❌ JSON parsing error: $e');
          developer.log('❌ Response body: ${response.body}');
          throw Exception('학원 정보 파싱에 실패했습니다: $e');
        }
      } else if (response.statusCode == 404) {
        // 404는 빈 배열 반환 (학원이 없는 경우)
        developer.log('⚠️ No academies found (404) - returning empty list');
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
      } else {
        developer.log('❌ API Error: ${response.statusCode}');
        developer.log('❌ Response body: ${response.body}');
        throw Exception('학원 정보를 가져오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching user academies: $e');
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
        developer.log('No access token available');
        throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/academy/academy-users/join/request',
      );
      developer.log('Sending academy join request to: $uri');

      final requestBody = json.encode({
        'academy': {'academy_code': academy_id},
        'user_id': user_id,
      });

      developer.log('Request body: $requestBody');
      developer.log(
        'academy_id type: ${academy_id.runtimeType}, value: $academy_id',
      );
      developer.log('user_id type: ${user_id.runtimeType}, value: $user_id');

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

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        developer.log('Academy join request successful');
        // 성공 응답이므로 아무것도 반환하지 않음 (응답 body 파싱 불필요)
        return;
      } else if (response.statusCode == 401) {
        throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
      } else {
        // 에러 응답 처리 (응답 body가 JSON이 아닐 수 있으므로 안전하게 처리)
        String errorMessage = '학원 등록 요청에 실패했습니다: ${response.statusCode}';

        developer.log('❌ user_id: $user_id (type: ${user_id.runtimeType})');

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
            developer.log('❌ Parsed error message: $serverMessage');
          } catch (e) {
            // JSON 파싱 실패 시 응답 body를 그대로 사용
            developer.log('Failed to parse error response as JSON: $e');
            errorMessage = '$errorMessage\n서버 응답: ${response.body}$requestInfo';
          }
        } else {
          errorMessage = '$errorMessage$requestInfo';
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log('Error joining academy: $e');
      rethrow;
    }
  }

  // TODO: 백엔드에서 academyId로 학원 상세 정보를 가져오는 API가 구현 중입니다.
  // 완료 후 frontend에서도 구현 예정입니다.

  /// 학원 목록을 SharedPreferences에 저장
  Future<void> saveAcademiesToCache(List<UserAcademyResponse> academies) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = json.encode(
        academies.map((academy) => academy.toJson()).toList(),
      );
      await prefs.setString(_academiesCacheKey, jsonData);
      developer.log('✅ 학원 목록 캐시 저장 완료 (${academies.length}개)');
    } catch (e) {
      developer.log('❌ 학원 목록 캐시 저장 실패: $e');
    }
  }

  /// SharedPreferences에서 학원 목록 로드
  Future<List<UserAcademyResponse>?> loadAcademiesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_academiesCacheKey);
      if (cachedJson == null) {
        return null;
      }

      final List<dynamic> data = json.decode(cachedJson);
      return data.map((item) => UserAcademyResponse.fromJson(item)).toList();
    } catch (e) {
      developer.log('❌ 학원 목록 캐시 로드 실패: $e');
      return null;
    }
  }

  /// 디폴트 학원 코드를 SharedPreferences에 저장
  Future<void> saveDefaultAcademyCode(String academyCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_defaultAcademyCodeKey, academyCode);
      developer.log('✅ 디폴트 학원 코드 저장 완료: $academyCode');
    } catch (e) {
      developer.log('❌ 디폴트 학원 코드 저장 실패: $e');
    }
  }

  /// SharedPreferences에서 디폴트 학원 코드 로드
  Future<String?> getDefaultAcademyCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_defaultAcademyCodeKey);
    } catch (e) {
      developer.log('❌ 디폴트 학원 코드 로드 실패: $e');
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
      developer.log('⚠️ 학원 목록이 비어있음');
      return null;
    }

    // 등록완료된 학원만 필터링
    final registeredAcademies = academies
        .where((academy) => academy.registerStatus == 'Y')
        .toList();

    if (registeredAcademies.isEmpty) {
      developer.log('⚠️ 등록완료된 학원이 없음');
      return null;
    }

    // 1. SharedPreferences에서 마지막 선택한 학원 코드 확인
    // (비동기이므로 동기적으로 처리하기 위해 Future를 사용하지 않음)
    // 대신 academies 리스트에서 직접 확인
    // 이 메서드는 나중에 getDefaultAcademyCode()와 함께 사용됨

    // 2. 등록완료된 첫 번째 학원 반환
    final firstRegistered = registeredAcademies.first;
    if (firstRegistered.academyCode != null) {
      developer.log(
        '✅ 디폴트 학원 선택: ${firstRegistered.academyName} (Code: ${firstRegistered.academyCode})',
      );
      return firstRegistered.academyCode;
    }

    developer.log('⚠️ 학원 코드가 없음');
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
      developer.log('⚠️ 학원 목록이 비어있음');
      return null;
    }

    // 등록완료된 학원만 필터링
    final registeredAcademies = academies
        .where((academy) => academy.registerStatus == 'Y')
        .toList();

    if (registeredAcademies.isEmpty) {
      developer.log('⚠️ 등록완료된 학원이 없음');
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
        developer.log(
          '✅ 저장된 디폴트 학원 사용: ${savedAcademy.academyName} (Code: ${savedAcademy.academyCode})',
        );
        return savedAcademy.academyCode;
      }
    }

    // 2. 저장된 학원이 없거나 유효하지 않으면 등록완료된 첫 번째 학원 반환
    final firstRegistered = registeredAcademies.first;
    if (firstRegistered.academyCode != null) {
      developer.log(
        '✅ 첫 번째 등록완료 학원 선택: ${firstRegistered.academyName} (Code: ${firstRegistered.academyCode})',
      );
      return firstRegistered.academyCode;
    }

    developer.log('⚠️ 학원 코드가 없음');
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
      developer.log('⚠️ 학원 코드 $academyCode에 해당하는 학원을 찾을 수 없음');
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
        print(
          '🔍 [AcademyService] API 호출 시작: uncachedIds=${uncachedIds.toList()}',
        );
        final token = await _authService.getAccessToken();
        if (token == null) {
          print('❌ [AcademyService] 인증 토큰 없음');
          developer.log('No access token available');
          throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
        }

        final uri = ApiConfig.getAcademyClassesUri(uncachedIds);
        print('🔍 [AcademyService] API URI: $uri');
        developer.log('Fetching classes from: $uri');

        final response = await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        print('🔍 [AcademyService] Response status: ${response.statusCode}');
        print('🔍 [AcademyService] Response body: ${response.body}');
        developer.log('Response status: ${response.statusCode}');
        developer.log('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          print('🔍 [AcademyService] API 응답 데이터: $data');
          print('🔍 [AcademyService] 응답 데이터 타입: ${data.runtimeType}');
          print('🔍 [AcademyService] 응답 데이터 길이: ${data.length}');

          // academyUserId == assigneeId 이므로, academyUserId를 키로 사용
          for (var item in data) {
            print('🔍 [AcademyService] 아이템: $item');
            print('🔍 [AcademyService] 아이템 타입: ${item.runtimeType}');
            if (item is Map) {
              print('🔍 [AcademyService] 아이템 키: ${item.keys.toList()}');
            } else {
              print('🔍 [AcademyService] 아이템 키: N/A');
            }

            final academyUserId = item['academyUserId']?.toString() ?? '';
            final className = item['className']?.toString() ?? '';
            print(
              '🔍 [AcademyService] 파싱: academyUserId=$academyUserId, className=$className',
            );
            print(
              '🔍 [AcademyService] academyUserId 타입: ${item['academyUserId'].runtimeType}',
            );
            print(
              '🔍 [AcademyService] className 타입: ${item['className'].runtimeType}',
            );

            if (academyUserId.isNotEmpty && className.isNotEmpty) {
              _classCache[academyUserId] = className;
              print('✅ [AcademyService] 캐시 저장: $academyUserId -> $className');
            } else {
              print(
                '⚠️ [AcademyService] 빈 값 발견: academyUserId=$academyUserId, className=$className',
              );
            }
          }

          developer.log('✅ Class names cached: ${_classCache.length} classes');
          print('✅ [AcademyService] 총 ${_classCache.length}개 클래스 캐시됨');
          print('🔍 [AcademyService] 현재 캐시 내용: $_classCache');
        } else if (response.statusCode == 401) {
          print('❌ [AcademyService] 인증 실패 (401)');
          throw Exception('인증에 실패했습니다. 다시 로그인해주세요.');
        } else {
          print('⚠️ [AcademyService] API 실패: ${response.statusCode}');
          developer.log(
            '⚠️ Failed to fetch class names: ${response.statusCode}',
          );
          // API 실패 시 빈 맵 반환 (에러는 throw하지 않음)
        }
      } catch (e, stackTrace) {
        print('❌ [AcademyService] 에러 발생: $e');
        print('❌ [AcademyService] 스택 트레이스: $stackTrace');
        developer.log('⚠️ Error fetching classes: $e');
        // 에러 발생 시에도 캐시된 데이터는 반환
      }
    } else {
      print('ℹ️ [AcademyService] 모든 ID가 캐시에 있음, API 호출 스킵');
    }

    // 3. 캐시에서 결과 반환 (요청한 모든 ID에 대해)
    final result = Map.fromEntries(
      assigneeIds.map((id) => MapEntry(id, _classCache[id] ?? '')),
    );
    print('🔍 [AcademyService] 반환할 classMap: $result');
    return result;
  }

  /// 클래스 정보 캐시 초기화
  void clearClassCache() {
    _classCache.clear();
    developer.log('✅ Class cache cleared');
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
      developer.log('🔵 [UserAcademyResponse] Parsing JSON: ${json.keys}');

      // academy 객체 추출 (null 안전)
      final academy = json['academy'] as Map<String, dynamic>? ?? {};
      developer.log('🔵 [UserAcademyResponse] Academy object: ${academy.keys}');

      final academyName = academy['academy_name']?.toString() ?? '';
      final academyCode = academy['academy_code']?.toString();
      final registerStatus = json['register_status']?.toString() ?? 'P';

      developer.log(
        '🔵 [UserAcademyResponse] Parsed: name=$academyName, code=$academyCode, status=$registerStatus',
      );

      if (academyName.isEmpty) {
        developer.log(
          '⚠️ [UserAcademyResponse] Warning: academy_name is empty!',
        );
        developer.log('⚠️ [UserAcademyResponse] Full academy object: $academy');
      }

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
      developer.log('❌ [UserAcademyResponse] Error parsing: $e');
      developer.log('❌ [UserAcademyResponse] JSON data: $json');
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
