import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/back_button.dart' as custom;
import '../widgets/page_title.dart';
import '../widgets/verification_code_input.dart';
import '../widgets/next_button.dart';

class FindPasswordVerificationPage extends StatefulWidget {
  final String userName;

  const FindPasswordVerificationPage({super.key, required this.userName});

  @override
  State<FindPasswordVerificationPage> createState() =>
      _FindPasswordVerificationPageState();
}

class _FindPasswordVerificationPageState
    extends State<FindPasswordVerificationPage> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleBack() {
    Navigator.pop(context);
  }

  void _handleNext() {
    // TODO: Implement verification code validation
    if (_codeController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('4자리 인증번호를 입력해주세요.'),
          backgroundColor: Color(0xFFFF4258),
        ),
      );
      return;
    }

    // Navigate to reset password page
    Navigator.pushNamed(context, '/reset-password');
  }

  void _handleResendCode() {
    // TODO: Implement resend verification code
    print('Resending verification code...');
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
                      const PageTitle(text: '비밀번호 찾기'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${widget.userName}님, 환영합니다.',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      color: Color(0xFF5C5C5C),
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    '이메일로 보내드린 4자 코드를 입력해주세요.',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF5C5C5C),
                    ),
                  ),
                  const SizedBox(height: 24),
                  VerificationCodeInput(
                    length: 4,
                    onChanged: (code) {
                      _codeController.text = code;
                    },
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _handleResendCode,
                    child: const Text(
                      '인증번호를 받지 못했나요? 재전송',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Color(0xFFADADAD),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  NextButton(text: '다음', onPressed: _handleNext),
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
