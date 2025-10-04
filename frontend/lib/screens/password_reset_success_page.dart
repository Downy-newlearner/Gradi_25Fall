import 'package:flutter/material.dart';
import '../widgets/back_button.dart' as custom;
import '../widgets/page_title.dart';
import '../widgets/next_button.dart';

class PasswordResetSuccessPage extends StatefulWidget {
  const PasswordResetSuccessPage({super.key});

  @override
  State<PasswordResetSuccessPage> createState() =>
      _PasswordResetSuccessPageState();
}

class _PasswordResetSuccessPageState extends State<PasswordResetSuccessPage> {
  void _handleBack() {
    // 로그인 페이지로 이동
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _handleLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24), // Top spacing
                // Back Button
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: custom.CustomBackButton(onPressed: _handleBack),
                  ),
                ),

                const SizedBox(
                  height: 7,
                ), // Space between back button and title
                // Page Title
                const PageTitle(text: '비밀번호 변경'),

                const SizedBox(
                  height: 48,
                ), // Space between title and result message
                // Result Message
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 34),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '비밀번호 변경이\n완료되었습니다.',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                        height: 1.193359375,
                        color: Color(0xFF5C5C5C),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 400,
                ), // Space between message and login button
                // Login Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 34),
                  child: NextButton(text: '로그인하기', onPressed: _handleLogin),
                ),

                const SizedBox(height: 60), // Bottom spacing
              ],
            ),
          ),
        ),
      ),
    );
  }
}
