import 'package:flutter/material.dart';

class UserIDCard extends StatelessWidget {
  final String userName;
  final String userId;
  final double? width;
  final double? height;

  const UserIDCard({
    Key? key,
    required this.userName,
    required this.userId,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 193,
      height: height ?? 58,
      child: RichText(
        textAlign: TextAlign.left,
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5C5C5C),
            height: 1.193,
          ),
          children: [
            TextSpan(text: '${userName}님의 아이디는\n'),
            TextSpan(text: userId),
          ],
        ),
      ),
    );
  }
}
