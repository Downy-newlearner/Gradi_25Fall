import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_header_title.dart';
import '../../widgets/app_header_menu_button.dart';

/// 알림 페이지
/// 학습 관련 알림, 숙제 마감 알림, 학원 공지사항 등을 표시하는 페이지
///
/// 구성:
/// 1. 헤더: 알림 타이틀 + 전체 읽음 처리 버튼
/// 2. 알림 목록: 타입별 아이콘, 내용, 시간, 읽음/안읽음 상태
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // TODO: 서버에서 알림 데이터 가져오기
  final List<NotificationItem> _notifications = [
    NotificationItem(
      type: NotificationType.homework,
      title: '숙제 마감 알림',
      message: '블랙라벨 중등수학 1-1 - 1단원 숙제가 내일 마감됩니다.',
      time: DateTime.now().subtract(const Duration(minutes: 10)),
      isRead: false,
    ),
    NotificationItem(
      type: NotificationType.learningReminder,
      title: '학습 리마인더',
      message: '오늘의 학습을 시작할 시간입니다!',
      time: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
    ),
    NotificationItem(
      type: NotificationType.academyNotice,
      title: '학원 공지사항',
      message: '정다훈 학원: 다음 주 월요일은 휴원입니다.',
      time: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: true,
    ),
    NotificationItem(
      type: NotificationType.grading,
      title: '채점 완료',
      message: '수능완성 영어 2026 - 독해 1~10 채점이 완료되었습니다.',
      time: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
    ),
    NotificationItem(
      type: NotificationType.achievement,
      title: '학습 목표 달성',
      message: '연속 학습 7일 달성! 축하합니다 🎉',
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(unreadCount),

            // 알림 목록
            Expanded(
              child: _notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationCard(
                          _notifications[index],
                          index,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int unreadCount) {
    return AppHeader(
      title: Row(
        children: [
          const AppHeaderTitle('알림'),
          if (unreadCount > 0) ...[
            const SizedBox(width: 8), // ✅ Rule 1: spacing은 OK
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ), // ✅ Rule 5: trailing comma
              decoration: BoxDecoration(
                color: const Color(0xFFF44336),
                borderRadius: BorderRadius.circular(10),
              ), // ✅ Rule 5: trailing comma
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Colors.white,
                ), // ✅ Rule 5: trailing comma
              ), // ✅ Rule 5: trailing comma
            ),
          ],
          const Spacer(),
        ],
      ), // ✅ Rule 5: trailing comma
      trailing: unreadCount > 0
          ? TextButton(
              onPressed: _markAllAsRead,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ), // ✅ Rule 5: trailing comma
              child: const Text(
                '모두 읽음',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFFAC5BF8),
                ), // ✅ Rule 5: trailing comma
              ), // ✅ Rule 5: trailing comma
            )
          : const AppHeaderMenuButton(),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification, int index) {
    return Dismissible(
      key: Key('notification_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        setState(() {
          _notifications.removeAt(index);
        });
        // TODO: 서버에 삭제 요청
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('알림이 삭제되었습니다')));
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF44336),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: notification.isRead ? Colors.white : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              _markAsRead(notification);
              // TODO: 알림 상세 페이지로 이동 또는 관련 페이지로 이동
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: notification.isRead
                      ? const Color(0xFFE9ECEF)
                      : const Color(0xFFAC5BF8),
                  width: notification.isRead ? 1 : 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 알림 타입 아이콘
                  _buildNotificationIcon(notification.type),
                  const SizedBox(width: 12),

                  // 알림 내용
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: notification.isRead
                                      ? FontWeight.w600
                                      : FontWeight.w700,
                                  fontSize: 16,
                                  color: const Color(0xFF333333),
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFAC5BF8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(notification.time),
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.homework:
        icon = Icons.assignment_outlined;
        color = const Color(0xFFFF9800);
        break;
      case NotificationType.learningReminder:
        icon = Icons.schedule;
        color = const Color(0xFFAC5BF8);
        break;
      case NotificationType.academyNotice:
        icon = Icons.school_outlined;
        color = const Color(0xFF2196F3);
        break;
      case NotificationType.grading:
        icon = Icons.check_circle_outline;
        color = const Color(0xFF4CAF50);
        break;
      case NotificationType.achievement:
        icon = Icons.emoji_events_outlined;
        color = const Color(0xFFFFC107);
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            '알림이 없습니다',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새로운 알림이 도착하면 여기에 표시됩니다',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _markAsRead(NotificationItem notification) {
    if (!notification.isRead) {
      setState(() {
        notification.isRead = true;
      });
      // TODO: 서버에 읽음 상태 업데이트
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
    // TODO: 서버에 일괄 읽음 상태 업데이트
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${time.year}.${time.month.toString().padLeft(2, '0')}.${time.day.toString().padLeft(2, '0')}';
    }
  }
}

/// 알림 타입
enum NotificationType {
  homework, // 숙제 관련
  learningReminder, // 학습 리마인더
  academyNotice, // 학원 공지사항
  grading, // 채점 완료
  achievement, // 학습 목표 달성
}

/// 알림 아이템 모델
class NotificationItem {
  final NotificationType type;
  final String title;
  final String message;
  final DateTime time;
  bool isRead;

  NotificationItem({
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
  });
}
