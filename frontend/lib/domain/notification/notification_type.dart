/// 알림 타입
enum NotificationType {
  homework, // 숙제 관련
  learningReminder, // 학습 리마인더
  academyNotice, // 학원 공지사항
  grading, // 채점 완료
  achievement, // 학습 목표 달성
}

/// NotificationType 확장 메서드
extension NotificationTypeExtension on NotificationType {
  /// NotificationType을 문자열로 변환
  String toStringValue() {
    switch (this) {
      case NotificationType.homework:
        return 'homework';
      case NotificationType.learningReminder:
        return 'learningReminder';
      case NotificationType.academyNotice:
        return 'academyNotice';
      case NotificationType.grading:
        return 'grading';
      case NotificationType.achievement:
        return 'achievement';
    }
  }
}

/// NotificationType 유틸리티
class NotificationTypeUtil {
  /// 문자열에서 NotificationType으로 변환
  static NotificationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'homework':
        return NotificationType.homework;
      case 'learningreminder':
      case 'learning_reminder':
        return NotificationType.learningReminder;
      case 'academynotice':
      case 'academy_notice':
        return NotificationType.academyNotice;
      case 'grading':
        return NotificationType.grading;
      case 'achievement':
        return NotificationType.achievement;
      default:
        return NotificationType.learningReminder; // 기본값
    }
  }
}
