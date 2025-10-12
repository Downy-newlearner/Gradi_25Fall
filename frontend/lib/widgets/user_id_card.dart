import 'package:flutter/material.dart';

class UserIDCard extends StatelessWidget {
  final String userName;
  final String userId;
  final double? width;

  const UserIDCard({
    super.key,
    required this.userName,
    required this.userId,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: width ?? double.infinity),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$userName님의 아이디는',
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C5C5C),
              height: 1.193,
            ),
          ),
          Text(
            '$userId입니다.',
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C5C5C),
              height: 1.193,
            ),
          ),
        ],
      ),
    );
  }
}
