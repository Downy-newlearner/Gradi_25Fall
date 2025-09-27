import 'package:flutter/material.dart';

class StatusBar extends StatelessWidget {
  final String time;
  final int batteryLevel;
  final bool isCharging;
  final bool showPercentage;

  const StatusBar({
    Key? key,
    this.time = '9:41',
    this.batteryLevel = 80,
    this.isCharging = false,
    this.showPercentage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 336.4,
      height: 21,
      padding: const EdgeInsets.only(left: 33, top: 17),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Time
          Container(
            width: 54,
            height: 21,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                time,
                style: const TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 1.294,
                  letterSpacing: -0.024,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          
          // Right Side - Battery, WiFi, Signal
          Container(
            width: 77.4,
            height: 13,
            child: Row(
              children: [
                // WiFi Icon
                Container(
                  width: 17,
                  height: 11.83,
                  child: CustomPaint(
                    painter: WifiIconPainter(),
                  ),
                ),
                
                const SizedBox(width: 26),
                
                // Mobile Signal Icon
                Container(
                  width: 18,
                  height: 12,
                  child: CustomPaint(
                    painter: SignalIconPainter(),
                  ),
                ),
                
                const SizedBox(width: 26),
                
                // Battery
                Container(
                  width: 27.4,
                  height: 13,
                  child: Row(
                    children: [
                      Container(
                        width: 25,
                        height: 13,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black.withOpacity(0.35),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 2,
                              top: 2,
                              child: Container(
                                width: (batteryLevel / 100) * 21,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1.4,
                        height: 4.22,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(2),
                            bottomRight: Radius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WifiIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDADADA)
      ..style = PaintingStyle.fill;

    // WiFi arcs
    canvas.drawArc(
      Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: 17, height: 5.39),
      -3.14, 3.14, false, paint..style = PaintingStyle.stroke..strokeWidth = 1,
    );
    
    canvas.drawArc(
      Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: 11.07, height: 4.13),
      -3.14, 3.14, false, paint..style = PaintingStyle.stroke..strokeWidth = 1,
    );
    
    canvas.drawArc(
      Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: 5.15, height: 3.83),
      -3.14, 3.14, false, paint..style = PaintingStyle.stroke..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SignalIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Signal bars
    canvas.drawRect(Rect.fromLTWH(0, 8, 3, 4), paint);
    canvas.drawRect(Rect.fromLTWH(4, 6, 3, 6), paint);
    canvas.drawRect(Rect.fromLTWH(8, 4, 3, 8), paint);
    canvas.drawRect(Rect.fromLTWH(12, 2, 3, 10), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


