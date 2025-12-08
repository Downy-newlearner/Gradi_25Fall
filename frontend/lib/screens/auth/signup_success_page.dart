import 'package:flutter/material.dart';
import '../../widgets/next_button.dart';

class SignUpSuccessPage extends StatelessWidget {
  const SignUpSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.075,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(height: MediaQuery.of(context).size.height * 0.15),

                  // 성공 아이콘
                  Container(
                    width: MediaQuery.of(context).size.width * 0.25,
                    height: MediaQuery.of(context).size.width * 0.25,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),

                  Container(height: MediaQuery.of(context).size.height * 0.04),

                  // 완료 메시지
                  const Text(
                    '회원가입이 완료되었습니다!',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  Container(height: MediaQuery.of(context).size.height * 0.02),

                  // 부가 설명
                  Text(
                    'GRADI와 함께 학습 여정을 시작해보세요',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  Container(height: MediaQuery.of(context).size.height * 0.08),

                  // 로그인하기 버튼
                  NextButton(
                    text: '로그인하기',
                    onPressed: () => _handleLogin(context),
                  ),

                  Container(height: MediaQuery.of(context).size.height * 0.075),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin(BuildContext context) {
    // 로그인 페이지로 이동 (모든 이전 페이지 스택 제거)
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}
