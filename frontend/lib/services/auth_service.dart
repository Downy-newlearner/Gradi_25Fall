import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as developer;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

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

  /// JWT 토큰에서 user_id 추출
  String? _extractUserIdFromToken(String token) {
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
      final payloadMap = json.decode(decodedString) as Map<String, dynamic>;

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

  /// 토큰 삭제 (로그아웃 시)
  Future<void> clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userIdKey);
      developer.log('Tokens cleared successfully');
    } catch (e) {
      developer.log('Failed to clear tokens: $e');
    }
  }
}
