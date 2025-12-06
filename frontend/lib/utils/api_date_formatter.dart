import 'kst_date_factory.dart';
import 'iso8601_formatter.dart';

/// API 요청용 날짜 포맷터
/// 
/// KST 날짜를 API 요청에 적합한 형식으로 변환합니다.
/// 내부적으로 KstDateFactory와 Iso8601Formatter를 사용합니다.
class ApiDateFormatter {
  /// KST 날짜의 시작 시간을 API 요청용 ISO8601 문자열로 변환
  /// 
  /// [kstDate]: KST 기준 날짜 (UTC 기반 DateTime)
  /// 반환값: ISO8601 문자열 with timezone (예: "2025-11-01T00:00:00+09:00")
  static String formatDayStart(DateTime kstDate) {
    final utcStart = KstDateFactory.getDayStartUtc(kstDate);
    return Iso8601Formatter.toKstIso8601(utcStart);
  }

  /// KST 날짜의 종료 시간을 API 요청용 ISO8601 문자열로 변환
  /// 
  /// [kstDate]: KST 기준 날짜 (UTC 기반 DateTime)
  /// 반환값: ISO8601 문자열 with timezone (예: "2025-11-01T23:59:59+09:00")
  static String formatDayEnd(DateTime kstDate) {
    final utcEnd = KstDateFactory.getDayEndUtc(kstDate);
    return Iso8601Formatter.toKstIso8601(utcEnd);
  }
}

