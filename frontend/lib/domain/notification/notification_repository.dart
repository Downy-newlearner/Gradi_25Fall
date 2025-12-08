import 'notification_entity.dart';

/// 알림 저장소 인터페이스
abstract class NotificationRepository {
  /// 알림 목록 가져오기 (최신순)
  Future<List<NotificationEntity>> fetchNotifications();

  /// 알림 저장
  Future<void> saveNotification(NotificationEntity notification);

  /// 알림 읽음 처리
  Future<void> markAsRead(String id);

  /// 전체 알림 읽음 처리
  Future<void> markAllAsRead();

  /// 알림 삭제
  Future<void> delete(String id);

  /// 전체 알림 삭제
  Future<void> clearAll();
}

