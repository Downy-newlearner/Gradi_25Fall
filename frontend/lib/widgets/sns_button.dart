import 'package:flutter/material.dart';

enum SNSProvider { kakao, google }

class SNSButton extends StatelessWidget {
  final SNSProvider provider;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;

  const SNSButton({
    Key? key,
    required this.provider,
    this.onPressed,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 50,
      height: height ?? 50,
      decoration: BoxDecoration(
        color: provider == SNSProvider.kakao 
            ? const Color(0xFFFFE812) // Kakao yellow
            : Colors.white,
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: _buildIcon(),
      ),
    );
  }

  Widget _buildIcon() {
    switch (provider) {
      case SNSProvider.kakao:
        return CustomPaint(
          size: const Size(28, 26),
          painter: KakaoIconPainter(),
        );
      case SNSProvider.google:
        return CustomPaint(
          size: const Size(27.32, 27.92),
          painter: GoogleIconPainter(),
        );
    }
  }
}

class KakaoIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Kakao logo simplified representation
    // This is a simplified version - in a real app you'd use the actual SVG
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: size.width * 0.8, height: size.height * 0.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Google logo simplified representation
    // This is a simplified version - in a real app you'd use the actual SVG
    paint.color = const Color(0xFF4285F4);
    canvas.drawOval(
      Rect.fromLTWH(0, 0, size.width * 0.3, size.height * 0.3),
      paint,
    );

    paint.color = const Color(0xFFEA4335);
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.7, 0, size.width * 0.3, size.height * 0.3),
      paint,
    );

    paint.color = const Color(0xFFFBBC05);
    canvas.drawOval(
      Rect.fromLTWH(0, size.height * 0.7, size.width * 0.3, size.height * 0.3),
      paint,
    );

    paint.color = const Color(0xFF34A853);
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.7, size.height * 0.7, size.width * 0.3, size.height * 0.3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


