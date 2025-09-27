import 'package:flutter/material.dart';
import '../widgets/back_button.dart' as custom;
import '../widgets/page_title.dart';
import '../widgets/next_button.dart';

class FindIDErrorPage extends StatefulWidget {
  const FindIDErrorPage({super.key});

  @override
  State<FindIDErrorPage> createState() => _FindIDErrorPageState();
}

class _FindIDErrorPageState extends State<FindIDErrorPage> {
  void _handleBack() {
    Navigator.pop(context);
  }

  void _handleRetry() {
    Navigator.pop(context); // Go back to FindIDPage to retry
  }

  void _handleBackToLogin() {
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      custom.CustomBackButton(onPressed: _handleBack),
                      const SizedBox(width: 20),
                      const PageTitle(text: '아이디 찾기'),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Color(0xFFFF4258),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '입력한 이메일로\n아이디를 찾을 수 없습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Color(0xFF5C5C5C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '입력하신 정보를 다시 확인해주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Color(0xFFA0A0A0),
                    ),
                  ),
                  const SizedBox(height: 40),
                  NextButton(text: '다시 시도', onPressed: _handleRetry),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _handleBackToLogin,
                    child: const Text(
                      '로그인으로 돌아가기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Color(0xFF666EDE),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60), // Bottom spacing
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
