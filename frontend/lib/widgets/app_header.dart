import 'package:flutter/material.dart';

/// 앱의 표준 헤더 위젯
///
/// Error Collector 규칙 준수:
/// - Rule 1: MediaQuery로 상대 크기 사용
/// - Rule 4: super.key constructor
/// - Rule 10: 고정 크기 회피
/// - Rule 14: 일관된 레이아웃 패턴
///
/// 사용 예시:
/// ```dart
/// AppHeader(
///   title: const AppHeaderTitle('문제집'),
///   trailing: const AppHeaderMenuButton(),
/// )
/// ```
class AppHeader extends StatelessWidget {
  /// 왼쪽 영역 위젯 (선택적)
  /// null이면 균형을 위한 공간이 자동으로 추가됨
  final Widget? leading;

  /// 중앙 타이틀 위젯 (필수)
  final Widget title;

  /// 오른쪽 액션 위젯 (선택적)
  final Widget? trailing;

  /// 타이틀 정렬 방식 (기본값: 중앙 정렬)
  /// - left: 왼쪽 정렬
  /// - center: 중앙 정렬
  final String titleAlignment;

  const AppHeader({
    super.key, // ✅ Rule 4: super.key
    this.leading,
    required this.title,
    this.trailing,
    this.titleAlignment = 'center',
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // ✅ Rule 1: 상대 크기 사용
    final horizontalPadding = screenWidth * 0.05;
    final topPadding = screenHeight * 0.021;
    final bottomPadding = screenHeight * 0.012;

    // ✅ Rule 1: 균형을 위한 공간도 상대 크기
    final balanceSpace = screenWidth * 0.06; // 24px ≈ 6% of 402px

    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        bottomPadding,
      ), // ✅ Rule 5: trailing comma
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ), // ✅ Rule 5: trailing comma
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Leading (왼쪽)
          if (leading != null)
            leading!
          else if (titleAlignment == 'left')
            SizedBox(width: balanceSpace) // ✅ Rule 1: 상대 크기 (왼쪽 정렬 시)
          else
            SizedBox(width: balanceSpace), // ✅ Rule 1: 상대 크기 (중앙 정렬 시)
          // Title (중앙 or 왼쪽)
          Expanded(
            child: titleAlignment == 'left'
                ? Align(alignment: Alignment.centerLeft, child: title)
                : Center(child: title), // ✅ Rule 5: trailing comma
          ), // ✅ Rule 5: trailing comma
          // Trailing (오른쪽)
          if (trailing != null)
            trailing!
          else
            SizedBox(width: balanceSpace), // ✅ Rule 1: 상대 크기
        ],
      ), // ✅ Rule 5: trailing comma
    );
  }
}
