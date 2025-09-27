import 'package:flutter/material.dart';
import '../widgets/back_button.dart' as custom;
import '../widgets/page_title.dart';
import '../widgets/verification_code_input.dart';
import '../widgets/next_button.dart';

class FindIDVerificationPage extends StatefulWidget {
  final String userName;

  const FindIDVerificationPage({Key? key, required this.userName})
    : super(key: key);

  @override
  State<FindIDVerificationPage> createState() => _FindIDVerificationPageState();
}

class _FindIDVerificationPageState extends State<FindIDVerificationPage> {
  String _verificationCode = '';

  void _handleBack() {
    Navigator.of(context).pop();
  }

  void _handleNext() {
    if (_verificationCode.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('4자리 인증번호를 입력해주세요.'),
          backgroundColor: Color(0xFFFF4258),
        ),
      );
      return;
    }

    // Navigate to result page
    Navigator.pushNamed(
      context,
      '/find-id-result',
      arguments: {
        'userName': widget.userName,
        'userId': '0311yjung', // Mock user ID
      },
    );
  }

  void _handleResendCode() {
    // Handle resend code logic here
    print('Resend code requested');
  }

  void _onCodeChanged(String code) {
    setState(() {
      _verificationCode = code;
    });
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
                const PageTitle(text: '아이디 찾기'),

                const SizedBox(
                  height: 42,
                ), // Space between title and welcome message
                // Welcome Message
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${widget.userName}님, 환영합니다.',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5C5C5C),
                        height: 1.193,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 7,
                ), // Space between welcome message and instructions
                // Instructions
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '이메일로 보내드린 4자 코드를 입력해주세요.',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5C5C5C),
                        height: 1.193,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 24,
                ), // Space between instructions and verification input
                // Verification Code Input
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: VerificationCodeInput(
                      length: 4,
                      onChanged: _onCodeChanged,
                      width: 248,
                      height: 50,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 13,
                ), // Space between verification input and resend link
                // Resend Code Link
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: _handleResendCode,
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFADADAD),
                            height: 1.193,
                          ),
                          children: [
                            const TextSpan(text: '인증번호를 받지 못했나요? '),
                            TextSpan(
                              text: '재전송',
                              style: TextStyle(
                                color: const Color(0xFFADADAD),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 161,
                ), // Space between resend link and next button
                // Next Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: NextButton(
                    text: '다음',
                    onPressed: _verificationCode.length == 4
                        ? _handleNext
                        : null,
                  ),
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
