import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import '../config/api_config.dart';

/// 인증 및 토큰 관리를 담당하는 서비스
///
/// DI Container에서 singleton으로 관리되며,
/// 더 이상 파일 내부에서 직접 싱글톤 패턴을 구현하지 않습니다.
class AuthService {
  AuthService();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _autoLoginKey = 'auto_login';
  static const String _saveAccountIdKey = 'save_account_id';
  static const String _savedAccountIdKey = 'saved_account_id';

  /// Refresh Token 저장
  Future<void> saveRefreshToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_refreshTokenKey, token);
      developer.log('Refresh token saved successfully');
    } catch (e) {
      developer.log('Failed to save refresh token: $e');
    }
  }

  /// Access Token 가져오기
  Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    } catch (e) {
      developer.log('Failed to get access token: $e');
      return null;
    }
  }

  /// Refresh Token 가져오기
  Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      developer.log('Failed to get refresh token: $e');
      return null;
    }
  }

  /// 로그인 상태 확인
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// JWT payload 디코딩
  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      // JWT는 header.payload.signature 형식
      final parts = token.split('.');
      if (parts.length != 3) {
        developer.log('Invalid JWT token format');
        return null;
      }

      // payload 부분 디코딩
      final payload = parts[1];

      // Base64 URL 디코딩 (패딩 추가)
      String normalizedPayload = payload
          .replaceAll('-', '+')
          .replaceAll('_', '/');
      switch (normalizedPayload.length % 4) {
        case 1:
          normalizedPayload += '===';
          break;
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
      }

      final decodedBytes = base64Url.decode(normalizedPayload);
      final decodedString = utf8.decode(decodedBytes);
      return json.decode(decodedString) as Map<String, dynamic>;
    } catch (e) {
      developer.log('Error decoding JWT payload: $e');
      return null;
    }
  }

  /// JWT 토큰 만료 확인
  bool isTokenExpired(String token) {
    try {
      final payload = _decodeJwtPayload(token);
      if (payload == null) return true;

      // exp (expiration) 필드 확인
      final exp = payload['exp'] as int?;
      if (exp == null) {
        developer.log('Token has no expiration field');
        return true; // exp가 없으면 만료된 것으로 간주
      }

      final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final isExpired = DateTime.now().isAfter(expirationTime);

      if (isExpired) {
        developer.log('Token expired at: ${expirationTime.toIso8601String()}');
      }

      return isExpired;
    } catch (e) {
      developer.log('Error checking token expiration: $e');
      return true; // 에러 발생 시 만료된 것으로 간주
    }
  }

  /// JWT 토큰이 곧 만료될 예정인지 확인 (사전 갱신용)
  /// [threshold]: 만료되기 전 얼마나 남았을 때 갱신할지 (기본값: 5분)
  bool isTokenExpiringSoon(
    String token, {
    Duration threshold = const Duration(minutes: 5),
  }) {
    try {
      final payload = _decodeJwtPayload(token);
      if (payload == null) return true;

      // exp (expiration) 필드 확인
      final exp = payload['exp'] as int?;
      if (exp == null) {
        developer.log('Token has no expiration field');
        return true; // exp가 없으면 곧 만료될 것으로 간주
      }

      final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      final timeUntilExpiry = expirationTime.difference(now);

      // 이미 만료되었거나, 임계값 이내로 남았으면 true
      final isExpiringSoon =
          timeUntilExpiry.isNegative || timeUntilExpiry <= threshold;

      if (isExpiringSoon && !timeUntilExpiry.isNegative) {
        developer.log(
          'Token expiring soon: ${timeUntilExpiry.inMinutes} minutes remaining (threshold: ${threshold.inMinutes} minutes)',
        );
      }

      return isExpiringSoon;
    } catch (e) {
      developer.log('Error checking token expiration soon: $e');
      return true; // 에러 발생 시 곧 만료될 것으로 간주
    }
  }

  /// JWT 토큰에서 user_id 추출
  String? _extractUserIdFromToken(String token) {
    try {
      final payloadMap = _decodeJwtPayload(token);
      if (payloadMap == null) {
        return null;
      }

      // user_id 또는 userId 필드 찾기
      final userId =
          payloadMap['user_id'] ??
          payloadMap['userId'] ??
          payloadMap['sub'] ??
          payloadMap['id'];

      if (userId != null) {
        developer.log('User ID extracted from token: $userId');
        return userId.toString();
      } else {
        developer.log('User ID not found in token payload: $payloadMap');
        return null;
      }
    } catch (e) {
      developer.log('Error extracting user ID from token: $e');
      return null;
    }
  }

  /// Access Token 저장 및 user_id 추출하여 저장
  Future<void> saveAccessToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, token);
      developer.log('Access token saved successfully');

      // JWT에서 user_id 추출하여 저장
      final userId = _extractUserIdFromToken(token);
      if (userId != null) {
        await prefs.setString(_userIdKey, userId);
        developer.log('User ID saved successfully: $userId');
      } else {
        developer.log('Warning: Could not extract user ID from token');
      }
    } catch (e) {
      developer.log('Failed to save access token: $e');
    }
  }

  /// User ID 가져오기
  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);

      // SharedPreferences에 없으면 토큰에서 추출 시도
      if (userId == null) {
        final token = await getAccessToken();
        if (token != null) {
          final extractedUserId = _extractUserIdFromToken(token);
          if (extractedUserId != null) {
            await prefs.setString(_userIdKey, extractedUserId);
            return extractedUserId;
          }
        }
      }

      return userId;
    } catch (e) {
      developer.log('Failed to get user ID: $e');
      return null;
    }
  }

  /// Refresh Token으로 Access Token 갱신
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        developer.log('❌ No refresh token found');
        return false;
      }

      developer.log('🔄 Refreshing access token...');

      // Refresh Token으로 새 Access Token 요청
      final response = await http
          .post(
            ApiConfig.getRefreshTokenUri(),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $refreshToken',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);

          // 새 Access Token 저장
          if (responseData['accessToken'] != null) {
            final newAccessToken = responseData['accessToken'] as String;
            await saveAccessToken(newAccessToken);

            // 새 Refresh Token이 있으면 함께 저장
            if (responseData['refreshToken'] != null) {
              await saveRefreshToken(responseData['refreshToken'] as String);
            }

            developer.log('✅ Access token refreshed successfully');
            return true;
          } else {
            developer.log('❌ Refresh response missing accessToken');
            return false;
          }
        } catch (e) {
          developer.log('❌ Error parsing refresh response: $e');
          return false;
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Refresh Token도 만료된 경우
        developer.log(
          '❌ Refresh token expired (${response.statusCode}) - 로그인 필요',
        );
        await clearTokens();
        return false;
      } else {
        developer.log('❌ Failed to refresh token: ${response.statusCode}');
        developer.log('   Response: ${response.body}');
        return false;
      }
    } catch (e) {
      developer.log('❌ Error refreshing access token: $e');
      return false;
    }
  }

  /// Access Token이 유효한지 확인하고 필요시 갱신 (사전 갱신 방식)
  /// 만료되기 5분 전에 자동으로 갱신 시도
  /// 반환값: 유효한 Access Token (갱신 성공 또는 이미 유효한 경우), null (갱신 실패)
  Future<String?> ensureValidAccessToken() async {
    var token = await getAccessToken();
    if (token == null) {
      developer.log('❌ No access token found');
      return null;
    }

    // 토큰이 곧 만료될 예정이면 (만료 5분 전) 사전 갱신 시도
    if (isTokenExpiringSoon(token)) {
      developer.log('⚠️ Access token expiring soon, refreshing proactively...');
      final refreshed = await refreshAccessToken();

      if (refreshed) {
        return await getAccessToken();
      } else {
        // 사전 갱신 실패 시, 이미 만료된 경우인지 확인
        final newToken = await getAccessToken();
        if (newToken != null && !isTokenExpired(newToken)) {
          // 갱신은 실패했지만 토큰이 아직 유효한 경우
          return newToken;
        }
        return null;
      }
    }

    // 토큰이 아직 유효하면 그대로 반환
    return token;
  }

  /// 자동 로그인 설정 저장
  Future<void> setAutoLogin(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoLoginKey, enabled);
      developer.log('Auto login setting saved: $enabled');
    } catch (e) {
      developer.log('Failed to save auto login setting: $e');
    }
  }

  /// 자동 로그인 설정 조회
  Future<bool> isAutoLoginEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_autoLoginKey) ?? false;
    } catch (e) {
      developer.log('Failed to get auto login setting: $e');
      return false;
    }
  }

  /// 아이디 저장 설정 저장
  Future<void> setSaveAccountId(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_saveAccountIdKey, enabled);
      developer.log('Save account ID setting saved: $enabled');
    } catch (e) {
      developer.log('Failed to save account ID setting: $e');
    }
  }

  /// 아이디 저장 설정 조회
  Future<bool> isSaveAccountIdEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_saveAccountIdKey) ?? false;
    } catch (e) {
      developer.log('Failed to get save account ID setting: $e');
      return false;
    }
  }

  /// 저장된 아이디 조회
  Future<String?> getSavedAccountId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_savedAccountIdKey);
    } catch (e) {
      developer.log('Failed to get saved account ID: $e');
      return null;
    }
  }

  /// 아이디 저장
  Future<void> saveAccountId(String accountId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedAccountIdKey, accountId);
      developer.log('Account ID saved: $accountId');
    } catch (e) {
      developer.log('Failed to save account ID: $e');
    }
  }

  /// 저장된 아이디 삭제
  Future<void> clearSavedAccountId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedAccountIdKey);
      developer.log('Saved account ID cleared');
    } catch (e) {
      developer.log('Failed to clear saved account ID: $e');
    }
  }

  /// 토큰 삭제 (로그아웃 시)
  /// [clearAutoLogin]: 자동 로그인 설정도 함께 삭제할지 여부 (기본값: true)
  Future<void> clearTokens({bool clearAutoLogin = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userIdKey);

      if (clearAutoLogin) {
        await prefs.remove(_autoLoginKey);
      }

      developer.log('Tokens cleared successfully');
    } catch (e) {
      developer.log('Failed to clear tokens: $e');
    }
  }

  Future<void> signOutFromServer() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        developer.log('⚠️ signOut skipped: no access token');
        return;
      }

      final response = await http.post(
        ApiConfig.getSignOutUri(),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log(
        '[AuthService] sign-out response: ${response.statusCode} ${response.body}',
      );
    } catch (e) {
      developer.log('⚠️ signOutFromServer failed: $e');
    }
  }
}
