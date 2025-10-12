import 'package:flutter/material.dart';
import '../../widgets/login_button.dart';

class PasswordResetSuccessPage extends StatelessWidget {
  const PasswordResetSuccessPage({super.key});

  void _handleLogin(BuildContext context) {
    // 로그인 페이지로 이동
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight =
        MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 120), // Top spacing
                  // Success Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B4EFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),

                  const SizedBox(height: 40),
                  // Success Message
                  const Text(
                    '비밀번호 변경 완료',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Sub Message
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      '새로운 비밀번호로\n로그인해주세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        height: 1.5,
                        color: Color(0xFF7C7C7C),
                      ),
                    ),
                  ),

                  const Expanded(child: SizedBox()), // Push button to bottom
                  // Login Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: LoginButton(
                      text: '로그인하기',
                      onPressed: () => _handleLogin(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
