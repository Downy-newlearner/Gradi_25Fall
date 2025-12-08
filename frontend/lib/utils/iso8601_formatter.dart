/// ISO8601 문자열 포맷터
/// 
/// UTC 기반 DateTime을 ISO8601 문자열로 변환합니다.
/// API 요청 시 KST 타임존 정보를 명시적으로 포함합니다.
class Iso8601Formatter {
  /// UTC DateTime을 KST 타임존이 포함된 ISO8601 문자열로 변환
  /// 
  /// [utcDateTime]: UTC 기반 DateTime
  /// 반환값: ISO8601 문자열 with timezone (예: "2025-11-01T00:00:00+09:00")
  /// 
  /// 주의: 입력 DateTime은 반드시 UTC 기반이어야 합니다.
  static String toKstIso8601(DateTime utcDateTime) {
    // UTC DateTime을 KST로 변환 (UTC + 9시간)
    final kstDateTime = utcDateTime.add(const Duration(hours: 9));
    
    // ISO8601 형식으로 변환 (KST 타임존 명시)
    return _formatWithTimezone(
      kstDateTime.year,
      kstDateTime.month,
      kstDateTime.day,
      kstDateTime.hour,
      kstDateTime.minute,
      kstDateTime.second,
      hoursOffset: 9, // KST = UTC+9
    );
  }

  /// ISO8601 형식 문자열 생성 (타임존 포함)
  /// 
  /// [year, month, day, hour, minute, second]: 날짜/시간 구성 요소
  /// [hoursOffset]: UTC로부터의 시간 오프셋 (KST는 +9)
  /// 반환값: ISO8601 문자열 (예: "2025-11-01T00:00:00+09:00")
  static String _formatWithTimezone(
    int year,
    int month,
    int day,
    int hour,
    int minute,
    int second, {
    required int hoursOffset,
  }) {
    final sign = hoursOffset >= 0 ? '+' : '-';
    final absOffset = hoursOffset.abs();
    final hours = absOffset.toString().padLeft(2, '0');
    final minutes = '00'; // KST는 정확히 9시간 오프셋
    
    final yearStr = year.toString().padLeft(4, '0');
    final monthStr = month.toString().padLeft(2, '0');
    final dayStr = day.toString().padLeft(2, '0');
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');
    final secondStr = second.toString().padLeft(2, '0');
    
    return '$yearStr-$monthStr-${dayStr}T$hourStr:$minuteStr:$secondStr$sign$hours:$minutes';
  }
}

