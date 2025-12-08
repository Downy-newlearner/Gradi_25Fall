import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../../domain/notification/notification_entity.dart';
import '../../domain/notification/notification_repository.dart';

/// 알림 상태 관리자 (ValueNotifier 기반)
class NotificationNotifier {
  final NotificationRepository repository;

  NotificationNotifier(this.repository);

  /// 알림 목록 상태
  final ValueNotifier<List<NotificationEntity>> notifications =
      ValueNotifier<List<NotificationEntity>>([]);

  /// 로딩 상태
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  /// 읽지 않은 알림 개수
  int get unreadCount =>
      notifications.value.where((n) => !n.isRead).length;

  /// 알림 목록 로드
  Future<void> load() async {
    isLoading.value = true;
    try {
      final list = await repository.fetchNotifications();
      notifications.value = list;
      developer.log('✅ 알림 목록 로드 완료: ${list.length}개');
    } catch (e) {
      developer.log('❌ 알림 목록 로드 실패: $e');
      notifications.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// 알림 읽음 처리
  Future<void> markAsRead(String id) async {
    try {
      await repository.markAsRead(id);
      // 로컬 상태 업데이트
      notifications.value = notifications.value
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList();
      developer.log('✅ 알림 읽음 처리 완료: $id');
    } catch (e) {
      developer.log('❌ 알림 읽음 처리 실패: $e');
      rethrow;
    }
  }

  /// 전체 알림 읽음 처리
  Future<void> markAllAsRead() async {
    try {
      await repository.markAllAsRead();
      // 로컬 상태 업데이트
      notifications.value =
          notifications.value.map((n) => n.copyWith(isRead: true)).toList();
      developer.log('✅ 전체 알림 읽음 처리 완료');
    } catch (e) {
      developer.log('❌ 전체 알림 읽음 처리 실패: $e');
      rethrow;
    }
  }

  /// 알림 삭제
  Future<void> delete(String id) async {
    try {
      await repository.delete(id);
      // 로컬 상태 업데이트
      notifications.value =
          notifications.value.where((n) => n.id != id).toList();
      developer.log('✅ 알림 삭제 완료: $id');
    } catch (e) {
      developer.log('❌ 알림 삭제 실패: $e');
      rethrow;
    }
  }

  /// FCM 알림 추가 (Repository 저장 + 로컬 상태 즉시 반영)
  Future<void> addFromFCM(NotificationEntity notification) async {
    try {
      await repository.saveNotification(notification);
      // 로컬 상태에 즉시 추가 (최신순 유지)
      final currentList = notifications.value;
      final filtered = currentList.where((n) => n.id != notification.id).toList();
      filtered.insert(0, notification);
      notifications.value = filtered;
      developer.log('✅ FCM 알림 추가 완료: ${notification.id}');
    } catch (e) {
      developer.log('❌ FCM 알림 추가 실패: $e');
      rethrow;
    }
  }

  /// 리소스 정리
  void dispose() {
    notifications.dispose();
    isLoading.dispose();
  }
}

