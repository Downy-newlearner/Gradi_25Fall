import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double? width;
  final double? height;

  const CustomBackButton({super.key, this.onPressed, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 38,
      height: height ?? 38,
      child: IconButton(
        onPressed: onPressed ?? () => Navigator.of(context).pop(),
        icon: CustomPaint(
          size: const Size(9.5, 19),
          painter: BackArrowPainter(),
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}

class BackArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5C5C5C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.17;

    final path = Path();
    // Draw left arrow
    path.moveTo(size.width * 0.8, 0);
    path.lineTo(0, size.height * 0.5);
    path.lineTo(size.width * 0.8, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
