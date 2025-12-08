import 'package:flutter/material.dart';
import '../../screens/grading_history/grading_history_page.dart';

/// 헤더 채점 히스토리 버튼 위젯
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
        Icons.history,
        color: Color(0xFF333333),
      ), // ✅ Rule 5: trailing comma
      onPressed:
          onPressed ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GradingHistoryPage(),
              ),
            );
          },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}
