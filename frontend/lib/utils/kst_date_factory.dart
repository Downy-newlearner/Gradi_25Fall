/// KST 날짜 생성 팩토리
/// 
/// 기기 타임존과 무관하게 항상 KST(UTC+9) 기준 날짜를 생성합니다.
/// 모든 DateTime은 UTC 기반으로 관리하여 타임존 왜곡을 방지합니다.
class KstDateFactory {
  /// 현재 시각을 KST 기준 날짜로 변환
  /// 
  /// 기기가 어느 타임존에 있든 항상 KST 기준의 "오늘" 날짜를 반환합니다.
  /// 반환값: UTC 기반 DateTime (날짜만 의미, 시간은 00:00:00 UTC)
  /// 
  /// 예: 미국 LA에서 실행해도 KST 기준 오늘이 반환됩니다.
  static DateTime getTodayKst() {
    // 1. UTC 시각을 가져옴
    final nowUtc = DateTime.now().toUtc();
    
    // 2. KST로 변환 (UTC + 9시간)
    final nowKst = nowUtc.add(const Duration(hours: 9));
    
    // 3. UTC 기반으로 날짜만 추출 (시간 정보 제거)
    // 중요: UTC로 생성하여 타임존 왜곡 방지
    return DateTime.utc(nowKst.year, nowKst.month, nowKst.day);
  }

  /// 주어진 날짜를 KST 기준 날짜로 변환
  /// 
  /// [date]: 변환할 날짜 (어떤 타임존이든 상관없음)
  /// 반환값: UTC 기반 DateTime (날짜만 의미, 시간은 00:00:00 UTC)
  /// 
  /// 예: DateTime(2025, 11, 1) (로컬) → DateTime.utc(2025, 11, 1) (KST 기준)
  static DateTime toKstDate(DateTime date) {
    // 1. UTC로 변환
    final utc = date.toUtc();
    
    // 2. KST로 변환 (UTC + 9시간)
    final kst = utc.add(const Duration(hours: 9));
    
    // 3. UTC 기반으로 날짜만 추출
    return DateTime.utc(kst.year, kst.month, kst.day);
  }

  /// KST 날짜의 시작 시간(00:00:00)을 UTC DateTime으로 생성
  /// 
  /// [kstDate]: KST 기준 날짜 (UTC 기반 DateTime)
  /// 반환값: UTC 기반 DateTime (해당 날짜의 00:00:00 KST를 UTC로 변환한 값)
  /// 
  /// 예: 2025-11-01 KST → 2025-10-31 15:00:00 UTC
  static DateTime getDayStartUtc(DateTime kstDate) {
    // KST 00:00:00 = UTC 15:00:00 (전날)
    // 따라서 KST 날짜에서 하루를 빼고 15시로 설정
    final previousDay = kstDate.subtract(const Duration(days: 1));
    return DateTime.utc(
      previousDay.year,
      previousDay.month,
      previousDay.day,
      15, // KST 00:00 = UTC 15:00 (전날)
      0,
      0,
    );
  }

  /// KST 날짜의 종료 시간(23:59:59)을 UTC DateTime으로 생성
  /// 
  /// [kstDate]: KST 기준 날짜 (UTC 기반 DateTime)
  /// 반환값: UTC 기반 DateTime (해당 날짜의 23:59:59 KST를 UTC로 변환한 값)
  /// 
  /// 예: 2025-11-01 KST → 2025-11-01 14:59:59 UTC
  static DateTime getDayEndUtc(DateTime kstDate) {
    // KST 23:59:59 = UTC 14:59:59 (당일)
    return DateTime.utc(
      kstDate.year,
      kstDate.month,
      kstDate.day,
      14, // KST 23:59 = UTC 14:59 (당일)
      59,
      59,
    );
  }
}

