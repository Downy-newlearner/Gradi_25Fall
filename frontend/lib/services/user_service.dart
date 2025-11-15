import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import '../models/user.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

/// 사용자 정보 관리 서비스
///
/// 주요 기능:
/// 1. 서버에서 사용자 정보 가져오기 (/me API)
/// 2. SharedPreferences에 캐싱
/// 3. 메모리 캐시로 빠른 접근
/// 4. 상태 변경 알림 (listeners)
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static const String _userDataKey = 'user_data';

  // 메모리 캐시 (빠른 접근)
  User? _cachedUser;

  // 상태 변경 리스너
  final List<Function(User?)> _listeners = [];

  /// 리스너 등록
  void addListener(Function(User?) listener) {
    _listeners.add(listener);
  }

  /// 리스너 제거
  void removeListener(Function(User?) listener) {
    _listeners.remove(listener);
  }

  /// 리스너들에게 알림
  void _notifyListeners() {
    for (var listener in _listeners) {
      listener(_cachedUser);
    }
  }

  /// 사용자 정보 가져오기 (캐시에서)
  User? getUser() {
    return _cachedUser;
  }

  /// 사용자 이름 가져오기 (편의 메서드)
  String? getUserName() {
    return _cachedUser?.name;
  }

  /// 사용자 ID 가져오기 (편의 메서드)
  int? getUserId() {
    return _cachedUser?.userId;
  }

  /// 프로필 이미지 URL 가져오기 (편의 메서드)
  String? getProfileImageUrl() {
    return _cachedUser?.profileImageUrl;
  }

  /// 로컬에 저장된 사용자 정보 로드 (앱 시작 시)
  Future<User?> loadUserFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);

      if (userDataString != null) {
        final userJson = json.decode(userDataString) as Map<String, dynamic>;
        _cachedUser = User.fromJson(userJson);
        developer.log('✅ User loaded from cache: ${_cachedUser?.name}');
        _notifyListeners();
        return _cachedUser;
      }
      developer.log('ℹ️ No cached user data found');
      return null;
    } catch (e) {
      developer.log('❌ Failed to load user from cache: $e');
      return null;
    }
  }

  /// 서버에서 사용자 정보 가져오기 (API 호출)
  /// 토큰 만료 시 자동으로 갱신 시도
  Future<User?> fetchUserFromServer() async {
    try {
      // 유효한 Access Token 확인 및 필요시 갱신
      final token = await AuthService().ensureValidAccessToken();
      if (token == null) {
        developer.log('❌ No valid access token available');
        return null;
      }

      developer.log('🌐 Fetching user info from server...');

      // API 호출
      var response = await http
          .get(
            ApiConfig.getMeUri(),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      // 401 에러 발생 시 토큰 갱신 후 재시도
      if (response.statusCode == 401) {
        developer.log('⚠️ Unauthorized (401): Attempting token refresh...');

        final refreshed = await AuthService().refreshAccessToken();
        if (refreshed) {
          // 갱신된 토큰으로 재시도
          final newToken = await AuthService().getAccessToken();
          if (newToken != null) {
            developer.log('🔄 Retrying request with refreshed token...');
            response = await http
                .get(
                  ApiConfig.getMeUri(),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $newToken',
                  },
                )
                .timeout(const Duration(seconds: 10));
          } else {
            developer.log('❌ Failed to get refreshed token');
            return null;
          }
        } else {
          developer.log('❌ Token refresh failed - 로그인 필요');
          return null;
        }
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        _cachedUser = User.fromJson(responseData);

        // SharedPreferences에 저장
        await _saveUserToCache(_cachedUser!);

        developer.log('✅ User fetched from server: ${_cachedUser?.name}');
        _notifyListeners();
        return _cachedUser;
      } else {
        developer.log('❌ Failed to fetch user: ${response.statusCode}');
        developer.log('   Response: ${response.body}');
        return null;
      }
    } catch (e) {
      developer.log('❌ Error fetching user from server: $e');
      return null;
    }
  }

  /// 사용자 정보 저장 (내부용)
  Future<void> _saveUserToCache(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = json.encode(user.toJson());
      await prefs.setString(_userDataKey, userDataString);
      developer.log('✅ User saved to cache');
    } catch (e) {
      developer.log('❌ Failed to save user to cache: $e');
    }
  }

  /// 사용자 정보 초기화 (앱 시작 시 또는 로그인 직후 호출)
  ///
  /// 전략:
  /// 1. 캐시에서 먼저 로드 (빠른 UI 표시)
  /// 2. 백그라운드에서 서버 동기화 (최신 데이터)
  Future<User?> initialize() async {
    developer.log('🔄 Initializing UserService...');

    // 1. 캐시에서 먼저 로드 (빠른 UI 표시)
    final cachedUser = await loadUserFromCache();

    // 2. 백그라운드에서 서버 동기화 (최신 데이터)
    fetchUserFromServer().catchError((e) {
      developer.log('⚠️ Background sync failed: $e');
      // 캐시가 있으면 그대로 사용
      return null;
    });

    return cachedUser;
  }

  /// 사용자 정보 강제 새로고침
  /// (프로필 수정 후 등)
  Future<User?> refresh() async {
    developer.log('🔄 Refreshing user data...');
    return await fetchUserFromServer();
  }

  /// 사용자 정보 삭제 (로그아웃 시)
  Future<void> clearUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      _cachedUser = null;
      developer.log('✅ User data cleared');
      _notifyListeners();
    } catch (e) {
      developer.log('❌ Failed to clear user data: $e');
    }
  }
}
