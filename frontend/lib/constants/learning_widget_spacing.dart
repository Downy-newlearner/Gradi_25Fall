import 'package:flutter/material.dart';

/// 연속 학습 위젯의 spacing 상수 정의
///
/// 디바이스 tier별로 고정 px 값을 제공합니다.
/// - Phone: 기본값
/// - Tablet: 중간 크기
/// - Large Tablet: 큰 태블릿
class LearningWidgetSpacing {
  LearningWidgetSpacing._();

  /// 디바이스가 태블릿인지 확인
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  /// 디바이스가 대형 태블릿인지 확인
  static bool isLargeTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 1200;
  }

  /// ListView 외부 padding (좌우)
  /// Phone: 20px, Tablet: 32px, Large Tablet: 40px
  static double getOuterPadding(BuildContext context) {
    if (isLargeTablet(context)) return 40.0;
    if (isTablet(context)) return 32.0;
    return 20.0;
  }

  /// DateItem 내부 padding (좌우)
  /// Phone: 4px, Tablet: 8px, Large Tablet: 12px
  static double getInnerPadding(BuildContext context) {
    if (isLargeTablet(context)) return 12.0;
    if (isTablet(context)) return 8.0;
    return 4.0;
  }

  /// Connector 너비 (연결선)
  /// Phone: 6px, Tablet: 10px, Large Tablet: 14px
  static double getConnectorWidth(BuildContext context) {
    if (isLargeTablet(context)) return 14.0;
    if (isTablet(context)) return 10.0;
    return 6.0;
  }

  /// 힌트 내부 좌우 padding
  /// Phone: 12px, Tablet: 16px, Large Tablet: 20px
  static double getHintInnerHorizontalPadding(BuildContext context) {
    if (isLargeTablet(context)) return 20.0;
    if (isTablet(context)) return 16.0;
    return 12.0;
  }

  /// 힌트 내부 상하 padding
  /// Phone: 8px, Tablet: 10px, Large Tablet: 12px
  static double getHintInnerVerticalPadding(BuildContext context) {
    if (isLargeTablet(context)) return 12.0;
    if (isTablet(context)) return 10.0;
    return 8.0;
  }

  /// 힌트 외부 좌우 padding (고정값)
  static const double hintOuterHorizontalPadding = 8.0;

  /// 힌트 외부 상하 padding (고정값)
  static const double hintOuterVerticalPadding = 8.0;
}

