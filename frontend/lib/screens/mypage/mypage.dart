import 'package:flutter/material.dart';

/// 마이페이지
/// 사용자 프로필, 학습 현황, 각종 설정 메뉴를 제공하는 페이지
///
/// 구성:
/// 1. 헤더: 마이페이지 타이틀 + 햄버거 메뉴
/// 2. 프로필 섹션: 프로필 이미지 + 이름 + 편집 버튼
/// 3. 학습 현황 카드 (추후 구현)
/// 4. 설정 메뉴 목록
class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  // TODO: 서버에서 사용자 정보 가져오기
  String _userName = '최윤정';
  String? _profileImageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(),

            // 메인 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // 프로필 섹션
                    _buildProfileSection(),

                    const SizedBox(height: 24),

                    // TODO: 학습 현황 카드 구현
                    _buildLearningStatusCard(),

                    const SizedBox(height: 24),

                    // 설정 메뉴 목록
                    _buildSettingsMenu(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 17, 20, 17),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const Text(
            '마이페이지',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF585B69),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF585B69), size: 24),
            onPressed: () {
              // TODO: 메뉴 기능 구현
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('메뉴 기능 구현 예정')),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 프로필 섹션
  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 프로필 이미지
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFE9ECEF),
              shape: BoxShape.circle,
            ),
            child: _profileImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      _profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 32,
                          color: Color(0xFF999999),
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 32,
                    color: Color(0xFF999999),
                  ),
          ),
          const SizedBox(width: 16),

          // 이름
          Expanded(
            child: Text(
              _userName,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF333333),
              ),
            ),
          ),

          // 편집 버튼
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 24),
            color: const Color(0xFF666666),
            onPressed: () {
              // TODO: 프로필 편집 페이지로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('프로필 편집 기능 구현 예정')),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 학습 현황 카드
  /// TODO: 추후 구현 예정
  /// - 연속 학습 일수
  /// - 주간/월간 학습 통계
  /// - 최근 학습 문제집
  /// - 전체 진행률
  Widget _buildLearningStatusCard() {
    return Container(
      width: double.infinity,
      height: 150,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          '학습 현황\n(추후 구현 예정)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF999999),
          ),
        ),
      ),
    );
  }

  /// 설정 메뉴 목록
  Widget _buildSettingsMenu() {
    final menuItems = [
      _MenuItem(
        icon: Icons.smartphone,
        title: '화면',
        route: '/mypage/display-settings',
      ),
      _MenuItem(
        icon: Icons.assignment_outlined,
        title: '숙제 현황',
        route: '/mypage/homework-status',
      ),
      _MenuItem(
        icon: Icons.bar_chart_outlined,
        title: '학습 통계/학습 리포트',
        route: '/mypage/learning-statistics',
      ),
      _MenuItem(
        icon: Icons.person_outline,
        title: '계정 관리',
        route: '/mypage/account-management',
      ),
      _MenuItem(
        icon: Icons.school_outlined,
        title: '학원 관리',
        route: '/mypage/academy-management',
      ),
      _MenuItem(
        icon: Icons.notifications_outlined,
        title: '알림 설정',
        route: '/mypage/notification-settings',
      ),
    ];

    return Column(
      children: menuItems.map((item) => _buildMenuItem(item)).toList(),
    );
  }

  /// 개별 메뉴 아이템
  Widget _buildMenuItem(_MenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, item.route);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE9ECEF)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 24,
                  color: const Color(0xFF666666),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: Color(0xFF999999),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 메뉴 아이템 모델
class _MenuItem {
  final IconData icon;
  final String title;
  final String route;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.route,
  });
}

