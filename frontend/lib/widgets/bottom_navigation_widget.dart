import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomNavigationWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChanged;

  const BottomNavigationWidget({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

  void _handleTabChange(int index) {
    if (index == currentIndex) return; // 현재 탭이면 아무것도 하지 않음
    onTabChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: Row(
        children: [
          _buildNavItem('Home', '홈', 0),
          _buildNavItem('Textbook', '문제집', 1),
          _buildNavItem('Upload_image', '이미지업로드', 2),
          _buildNavItem('Academy', '학원', 3),
          _buildNavItem('Mypage', '마이페이지', 4),
          _buildNavItem('Alarm', '알람', 5),
        ],
      ),
    );
  }

  Widget _buildNavItem(String iconName, String label, int index) {
    final isActive = currentIndex == index;
    final iconPath = isActive
        ? 'assets/images/icons/${iconName}_selected.svg'
        : 'assets/images/icons/${iconName}_unselected.svg';

    return Expanded(
      child: GestureDetector(
        onTap: () => _handleTabChange(index),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // SVG 아이콘
              SvgPicture.asset(iconPath, width: 24, height: 24),
              const SizedBox(height: 4),
              // 텍스트
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 10,
                  color: isActive
                      ? const Color(0xFFAC5BF8)
                      : const Color(0xFFADADAD),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
