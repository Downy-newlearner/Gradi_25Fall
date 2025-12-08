import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final double widthFactor; // 화면 너비 대비 로고 너비 비율

  const AppLogo({super.key, this.width, this.height, this.widthFactor = 0.7});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double targetWidth = width ?? (screenWidth * widthFactor);

    return Container(
      width: targetWidth,
      height: height,
      constraints: BoxConstraints(
        maxWidth: screenWidth * 0.9, // 화면 너비의 90%를 넘지 않음
        minWidth: 200, // 최소 너비 보장
        maxHeight: height ?? 200, // 최대 높이 제한
      ),
      child: FittedBox(
        fit: BoxFit.contain, // 주어진 폭 안에서 자동 스케일
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFAC5BF8), // rgba(172, 91, 248, 1)
              Color(0xFF636ACF), // rgba(99, 106, 207, 1)
            ],
            stops: [0.09, 0.92],
            transform: GradientRotation(2.67), // 153 degrees in radians
          ).createShader(bounds),
          child: const Text(
            'GRADI',
            style: TextStyle(
              fontFamily: 'AppleSDGothicNeoH00',
              fontSize: 96, // 기준 폰트 크기 (FittedBox가 스케일 조정)
              fontWeight: FontWeight.w400,
              height: 1.491,
              letterSpacing: -0.06,
              color: Colors.white, // This will be masked by the gradient
            ),
          ),
        ),
      ),
    );
  }
}
