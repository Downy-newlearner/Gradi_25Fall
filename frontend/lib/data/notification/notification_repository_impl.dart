import 'dart:developer' as developer;
import '../../domain/notification/notification_entity.dart';
import '../../domain/notification/notification_repository.dart';
import 'notification_local_data_source.dart';

/// 알림 저장소 구현체 (SharedPreferences 기반)
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationLocalDataSource local;

  NotificationRepositoryImpl(this.local);

  static const int _maxCount = 100; // 최대 알림 개수

  @override
  Future<List<NotificationEntity>> fetchNotifications() async {
    try {
      final rawList = await local.loadRawList();
      final list = rawList
          .map((json) => NotificationEntity.fromJson(json))
          .toList()
        ..sort((a, b) => b.time.compareTo(a.time)); // 최신순 정렬

      return list;
    } catch (e) {
      developer.log('❌ 알림 목록 로드 실패: $e');
      return [];
    }
  }

  @override
  Future<void> saveNotification(NotificationEntity notification) async {
    try {
      final list = await fetchNotifications();

      // 중복 제거 (동일 id 제거)
      final filtered = list.where((n) => n.id != notification.id).toList();

      // 새 알림을 맨 앞에 추가
      filtered.insert(0, notification);

      // 최대 개수 제한
      final truncated = filtered.take(_maxCount).toList();

      // 저장
      await local.saveRawList(
        truncated.map((e) => e.toJson()).toList(),
      );

      developer.log('✅ 알림 저장 완료: ${notification.id}');
    } catch (e) {
      developer.log('❌ 알림 저장 실패: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      final list = await fetchNotifications();
      final updated = list.map((n) {
        if (n.id == id) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      await local.saveRawList(
        updated.map((e) => e.toJson()).toList(),
      );

      developer.log('✅ 알림 읽음 처리 완료: $id');
    } catch (e) {
      developer.log('❌ 알림 읽음 처리 실패: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final list = await fetchNotifications();
      final updated = list.map((n) => n.copyWith(isRead: true)).toList();

      await local.saveRawList(
        updated.map((e) => e.toJson()).toList(),
      );

      developer.log('✅ 전체 알림 읽음 처리 완료');
    } catch (e) {
      developer.log('❌ 전체 알림 읽음 처리 실패: $e');
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final list = await fetchNotifications();
      final filtered = list.where((n) => n.id != id).toList();

      await local.saveRawList(
        filtered.map((e) => e.toJson()).toList(),
      );

      developer.log('✅ 알림 삭제 완료: $id');
    } catch (e) {
      developer.log('❌ 알림 삭제 실패: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await local.saveRawList([]);
      developer.log('✅ 전체 알림 삭제 완료');
    } catch (e) {
      developer.log('❌ 전체 알림 삭제 실패: $e');
      rethrow;
    }
  }
}

