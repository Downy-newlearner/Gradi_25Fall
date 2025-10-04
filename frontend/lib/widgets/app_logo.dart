import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;

  const AppLogo({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 249,
      height: height ?? 133,
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
            fontSize: 88.9781494140625,
            fontWeight: FontWeight.w400,
            height: 1.491,
            letterSpacing: -0.06,
            color: Colors.white, // This will be masked by the gradient
          ),
        ),
      ),
    );
  }
}
