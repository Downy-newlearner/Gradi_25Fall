import 'package:flutter/material.dart';

/// 헤더 메뉴 버튼 표준 위젯
class AppHeaderMenuButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AppHeaderMenuButton({
    super.key, // ✅ Rule 4
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.menu,
        color: Color(0xFF333333),
      ), // ✅ Rule 5: trailing comma
      onPressed:
          onPressed ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('메뉴 기능 구현 예정'),
              ), // ✅ Rule 5: trailing comma
            );
          },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}
