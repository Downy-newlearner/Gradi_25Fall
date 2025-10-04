import 'package:flutter/material.dart';

class LinksSection extends StatelessWidget {
  final VoidCallback? onSignUp;
  final VoidCallback? onFindID;
  final VoidCallback? onFindPW;

  const LinksSection({super.key, this.onSignUp, this.onFindID, this.onFindPW});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 244,
      height: 17,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 회원가입
          GestureDetector(
            onTap: onSignUp,
            child: Text(
              '회원가입',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.193,
                color: Color(0xFF666EDE),
              ),
            ),
          ),

          // 구분선 1
          SizedBox(
            width: 1,
            height: 14,
            child: Container(color: const Color(0xFFCBCBCB)),
          ),

          // 아이디 찾기
          GestureDetector(
            onTap: onFindID,
            child: Text(
              '아이디 찾기',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.193,
                color: Color(0xFFA0A0A0),
              ),
            ),
          ),

          // 구분선 2
          SizedBox(
            width: 1,
            height: 14,
            child: Container(color: const Color(0xFFCBCBCB)),
          ),

          // 비밀번호 찾기
          GestureDetector(
            onTap: onFindPW,
            child: Text(
              '비밀번호 찾기',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.193,
                color: Color(0xFFA0A0A0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
