import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 알림 로컬 데이터 소스 (SharedPreferences 직접 접근)
class NotificationLocalDataSource {
  static const String _key = 'notifications_list';

  final SharedPreferences prefs;

  NotificationLocalDataSource(this.prefs);

  /// 알림 목록 로드 (JSON 문자열을 List<Map>으로 변환)
  Future<List<Map<String, dynamic>>> loadRawList() async {
    final jsonString = prefs.getString(_key);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      // JSON 파싱 실패 시 빈 리스트 반환
      return [];
    }
  }

  /// 알림 목록 저장 (List<Map>을 JSON 문자열로 저장)
  Future<void> saveRawList(List<Map<String, dynamic>> items) async {
    final jsonString = jsonEncode(items);
    await prefs.setString(_key, jsonString);
  }
}

