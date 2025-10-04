import 'package:flutter/material.dart';

class SNSDivider extends StatelessWidget {
  final String text;
  final double? width;
  final double? height;

  const SNSDivider({
    super.key,
    this.text = 'SNS 간편 로그인',
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 339,
      height: height ?? 17,
      child: Row(
        children: [
          // Left line
          Expanded(
            child: SizedBox(
              height: 1,
              child: Container(color: const Color(0xFFCBCBCB)),
            ),
          ),

          // Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.193,
                color: Color(0xFFA0A0A0),
              ),
            ),
          ),

          // Right line
          Expanded(
            child: SizedBox(
              height: 1,
              child: Container(color: const Color(0xFFCBCBCB)),
            ),
          ),
        ],
      ),
    );
  }
}
