import 'package:flutter/material.dart';
import '../widgets/bottom_navigation_widget.dart';
import 'home_page.dart';
import 'workbook/workbook_page.dart';
import 'academy/academy_page.dart';
import 'mypage/mypage.dart';
import 'notification/notification_page.dart';
import 'upload/upload_images_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  bool _handledRouteArgs = false;

  // HomePage의 State에 접근하기 위한 GlobalKey
  final GlobalKey<State<HomePage>> _homePageKey = GlobalKey();
  // UploadImagesPage의 State에 접근하기 위한 GlobalKey
  final GlobalKey<State<UploadImagesPage>> _uploadPageKey = GlobalKey();
  // WorkbookPage의 State에 접근하기 위한 GlobalKey
  final GlobalKey<State<WorkbookPage>> _workbookPageKey = GlobalKey();
  // AcademyPage의 State에 접근하기 위한 GlobalKey
  final GlobalKey<State<AcademyPage>> _academyPageKey = GlobalKey();
  // NotificationPage의 State에 접근하기 위한 GlobalKey
  final GlobalKey<State<NotificationPage>> _notificationPageKey = GlobalKey();

  // 모든 탭 페이지들
  late final List<Widget> _pages = [
    HomePage(key: _homePageKey), // GlobalKey 전달
    WorkbookPage(key: _workbookPageKey), // GlobalKey 전달
    UploadImagesPage(key: _uploadPageKey), // GlobalKey 전달
    AcademyPage(key: _academyPageKey), // GlobalKey 전달
    const MyPage(),
    NotificationPage(key: _notificationPageKey), // GlobalKey 전달
  ];

  @override
  Widget build(BuildContext context) {
    _handleRouteArgumentsIfNeeded();
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationWidget(
        currentIndex: _currentIndex,
        onTabChanged: (index) {
          setState(() {
            _currentIndex = index;
          });

          // 홈 탭(인덱스 0)으로 전환 시 새로고침
          if (index == 0) {
            final homeState = _homePageKey.currentState;
            // dynamic으로 캐스팅하여 refresh() 메서드 호출
            if (homeState != null) {
              try {
                (homeState as dynamic).refresh();
              } catch (e) {
                // refresh() 메서드가 없는 경우 무시
              }
            }
          }

          // 문제집 탭(인덱스 1)으로 전환 시 새로고침
          if (index == 1) {
            final workbookState = _workbookPageKey.currentState;
            // dynamic으로 캐스팅하여 refresh() 메서드 호출
            if (workbookState != null) {
              try {
                (workbookState as dynamic).refresh();
              } catch (e) {
                // refresh() 메서드가 없는 경우 무시
              }
            }
          }

          // 이미지 업로드 탭(인덱스 2)으로 전환 시 새로고침
          if (index == 2) {
            final uploadState = _uploadPageKey.currentState;
            // dynamic으로 캐스팅하여 refresh() 메서드 호출
            if (uploadState != null) {
              try {
                (uploadState as dynamic).refresh();
              } catch (e) {
                // refresh() 메서드가 없는 경우 무시
              }
            }
          }

          // 학원 탭(인덱스 3)으로 전환 시 새로고침
          if (index == 3) {
            final academyState = _academyPageKey.currentState;
            // dynamic으로 캐스팅하여 refresh() 메서드 호출
            if (academyState != null) {
              try {
                (academyState as dynamic).refresh();
              } catch (e) {
                // refresh() 메서드가 없는 경우 무시
              }
            }
          }

          // 알림 탭(인덱스 5)으로 전환 시 새로고침
          if (index == 5) {
            final notificationState = _notificationPageKey.currentState;
            // dynamic으로 캐스팅하여 refresh() 메서드 호출
            if (notificationState != null) {
              try {
                (notificationState as dynamic).refresh();
              } catch (e) {
                // refresh() 메서드가 없는 경우 무시
              }
            }
          }
        },
      ),
    );
  }

  void _handleRouteArgumentsIfNeeded() {
    if (_handledRouteArgs) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['targetDate'] is String) {
      final targetDate = DateTime.tryParse(args['targetDate'] as String);
      if (targetDate != null) {
        _handledRouteArgs = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateHomeAndFocus(targetDate);
        });
      }
    }
  }

  void _navigateHomeAndFocus(DateTime date) {
    setState(() {
      _currentIndex = 0;
    });
    final homeState = _homePageKey.currentState;
    if (homeState != null) {
      try {
        (homeState as dynamic).focusOnDate(date);
      } catch (e) {
        try {
          (homeState as dynamic).refresh();
        } catch (_) {}
      }
    }
  }
}

// 미구현 페이지들을 위한 플레이스홀더
class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '$title 페이지',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '구현 예정입니다',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
