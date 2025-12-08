import 'package:flutter/material.dart';

/// 헤더 타이틀 표준 위젯
///
/// 일관된 텍스트 스타일을 제공
class AppHeaderTitle extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;

  const AppHeaderTitle(
    this.text, {
    super.key, // ✅ Rule 4
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign, // 왼쪽/중앙 정렬 제어
      style: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: Color(0xFF333333),
      ), // ✅ Rule 5: trailing comma
    );
  }
}
