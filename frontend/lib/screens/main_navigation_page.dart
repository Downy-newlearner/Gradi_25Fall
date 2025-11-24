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

  // HomePage의 State에 접근하기 위한 GlobalKey
  final GlobalKey<State<HomePage>> _homePageKey = GlobalKey();
  // AcademyPage의 State에 접근하기 위한 GlobalKey
  final GlobalKey<State<AcademyPage>> _academyPageKey = GlobalKey();

  // 모든 탭 페이지들
  late final List<Widget> _pages = [
    HomePage(key: _homePageKey), // GlobalKey 전달
    const WorkbookPage(),
    const UploadImagesPage(),
    AcademyPage(key: _academyPageKey), // GlobalKey 전달
    const MyPage(),
    const NotificationPage(),
  ];

  @override
  Widget build(BuildContext context) {
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
        },
      ),
    );
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
