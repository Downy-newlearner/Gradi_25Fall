import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'notification_type.dart';
import '../../utils/app_logger.dart';

/// 알림 엔티티 (도메인 모델)
class NotificationEntity {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;
  final Map<String, dynamic>? data;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    this.data,
  });

  /// Immutable copyWith 메서드
  NotificationEntity copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? time,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toStringValue(),
      'title': title,
      'message': message,
      'time': time.toIso8601String(),
      'isRead': isRead,
      if (data != null) 'data': data,
    };
  }

  /// JSON에서 생성
  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: json['id'] as String,
      type: NotificationTypeUtil.fromString(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      time: DateTime.parse(json['time'] as String),
      isRead: json['isRead'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  /// FCM RemoteMessage에서 생성
  factory NotificationEntity.fromRemoteMessage(RemoteMessage message) {
    appLog('[notification:notification_entity] fromRemoteMessage 호출');
    appLog(
      '[notification:notification_entity] 메시지 data: ${json.encode(message.data)}',
    );
    if (message.notification != null) {
      appLog(
        '[notification:notification_entity] notification.title: ${message.notification!.title}',
      );
      appLog(
        '[notification:notification_entity] notification.body: ${message.notification!.body}',
      );
    }
    appLog(
      '[notification:notification_entity] 전체 메시지 JSON: ${json.encode({
        'messageId': message.messageId,
        'data': message.data,
        'notification': message.notification != null ? {'title': message.notification!.title, 'body': message.notification!.body} : null,
        'sentTime': message.sentTime?.toIso8601String(),
      })}',
    );

    final data = message.data;
    final notification = message.notification;

    // ID 생성: messageId 우선, 없으면 data['notificationId'], 없으면 timestamp 기반
    final id =
        message.messageId ??
        data['notificationId'] ??
        'fcm_${DateTime.now().millisecondsSinceEpoch}';

    // 제목 추출: data['title'] 우선, 없으면 notification.title, 없으면 기본값
    final title = data['title'] as String? ?? notification?.title ?? '알림';

    // 타입 추출: data['type'] 우선, 없으면 title 기반으로 판단, 없으면 기본값
    final typeString = data['type'] as String?;
    final type = typeString != null
        ? NotificationTypeUtil.fromString(typeString)
        : NotificationTypeUtil.fromTitle(title);

    // 메시지 추출: data['message'] 우선, 없으면 notification.body, 없으면 기본값
    final messageText =
        data['message'] as String? ??
        data['body'] as String? ??
        notification?.body ??
        '';

    // 시간: sentTime 우선, 없으면 현재 시간
    final time = message.sentTime ?? DateTime.now();

    return NotificationEntity(
      id: id,
      type: type,
      title: title,
      message: messageText,
      time: time,
      isRead: false, // 새 알림은 항상 읽지 않음
      data: data.isNotEmpty ? data : null,
    );
  }
}
