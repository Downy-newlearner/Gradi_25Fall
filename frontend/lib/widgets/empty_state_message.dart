import 'package:flutter/material.dart';

/// 공통 Empty State 위젯
///
/// - 아이콘, 제목, 설명, 기본 액션 버튼을 일관된 스타일로 렌더링합니다.
/// - 레이아웃 배치는 부모에서 담당합니다 (예: Center, SingleChildScrollView 등).
class EmptyStateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final MainAxisAlignment mainAxisAlignment;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;

  const EmptyStateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.primaryActionLabel,
    this.onPrimaryAction,
  });

  /// 숙제 도메인용 프리셋
  const EmptyStateMessage.homework({
    super.key,
    String? title,
    String? description,
    String? primaryActionLabel,
    VoidCallback? onPrimaryAction,
  })  : icon = Icons.assignment_outlined,
        title = title ?? '등록된 숙제가 없어요.',
        description = description,
        primaryActionLabel = primaryActionLabel,
        onPrimaryAction = onPrimaryAction,
        mainAxisAlignment = MainAxisAlignment.center;

  /// 문제집 도메인용 프리셋
  const EmptyStateMessage.workbook({
    super.key,
    String? title,
    String? description,
    String? primaryActionLabel,
    VoidCallback? onPrimaryAction,
  })  : icon = Icons.book_outlined,
        title = title ?? '현재 등록된 문제집이 없어요.',
        description = description,
        primaryActionLabel = primaryActionLabel,
        onPrimaryAction = onPrimaryAction,
        mainAxisAlignment = MainAxisAlignment.center;

  /// 학원 도메인용 프리셋
  const EmptyStateMessage.academy({
    super.key,
    String? title,
    String? description,
    String? primaryActionLabel,
    VoidCallback? onPrimaryAction,
  })  : icon = Icons.school_outlined,
        title = title ?? '등록된 학원이 없어요.',
        description = description,
        primaryActionLabel = primaryActionLabel,
        onPrimaryAction = onPrimaryAction,
        mainAxisAlignment = MainAxisAlignment.center;

  /// 클래스/반 도메인용 프리셋
  const EmptyStateMessage.classRoom({
    super.key,
    String? title,
    String? description,
    String? primaryActionLabel,
    VoidCallback? onPrimaryAction,
  })  : icon = Icons.group_outlined,
        title = title ?? '등록된 클래스가 없어요.',
        description = description,
        primaryActionLabel = primaryActionLabel,
        onPrimaryAction = onPrimaryAction,
        mainAxisAlignment = MainAxisAlignment.center;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Icon(
        icon,
        size: 64,
        color: const Color(0xFF999999),
      ),
      const SizedBox(height: 16),
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: Color(0xFF666666),
        ),
      ),
    ];

    if (description != null && description!.isNotEmpty) {
      children.addAll([
        const SizedBox(height: 8),
        Text(
          description!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: Color(0xFF999999),
          ),
        ),
      ]);
    }

    if (primaryActionLabel != null && onPrimaryAction != null) {
      children.addAll([
        const SizedBox(height: 24),
        SizedBox(
          width: 160,
          child: ElevatedButton(
            onPressed: onPrimaryAction,
            child: Text(
              primaryActionLabel!,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ]);
    }

    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}


