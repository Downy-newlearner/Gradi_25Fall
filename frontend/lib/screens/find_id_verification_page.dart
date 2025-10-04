import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import '../widgets/back_button.dart' as custom;
import '../widgets/page_title.dart';
import '../widgets/verification_code_input.dart';
import '../widgets/next_button.dart';

class FindIDVerificationPage extends StatefulWidget {
  const FindIDVerificationPage({super.key});

  @override
  State<FindIDVerificationPage> createState() => _FindIDVerificationPageState();
}

class _FindIDVerificationPageState extends State<FindIDVerificationPage> {
  String _verificationCode = '';
  bool _isLoading = false;
  String? _userName;
  String? _email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // arguments에서 데이터 추출
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _userName = args['userName'] as String?;
      _email = args['email'] as String?;
    }
  }

  void _handleBack() {
    Navigator.of(context).pop();
  }

  void _handleNext() async {
    if (_verificationCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('6자리 인증번호를 입력해주세요.'),
          backgroundColor: Color(0xFFFF4258),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 개발 환경에서 SSL 인증서 검증 우회 (프로덕션에서는 제거 필요)
      HttpOverrides.global = MyHttpOverrides();

      // 서버 IP 설정 (필요에 따라 변경)
      const String serverIp = '3.34.214.133'; // 실제 서버 IP로 변경해주세요
      const String url = 'https://$serverIp/verify/find_account';

      // 요청 데이터 준비
      final Map<String, String> requestData = {
        'email': _email ?? '',
        'code': _verificationCode,
      };

      developer.log('Sending verification request: $requestData');

      // API 호출
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          // 성공 시 결과 페이지로 이동
          Navigator.pushNamed(
            context,
            '/find-id-result',
            arguments: {
              'userName': responseData['data']['name'] ?? _userName ?? '',
              'userId': responseData['data']['account_id'] ?? '',
            },
          );
        } else {
          // 인증 실패
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('인증번호가 올바르지 않습니다.'),
                backgroundColor: Color(0xFFFF4258),
              ),
            );
          }
        }
      } else {
        // 서버 오류
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('서버 오류가 발생했습니다. 다시 시도해주세요.'),
              backgroundColor: Color(0xFFFF4258),
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Error during verification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('네트워크 오류가 발생했습니다. 다시 시도해주세요.'),
            backgroundColor: Color(0xFFFF4258),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleResendCode() {
    // Handle resend code logic here
    developer.log('Resend code requested');
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
                      '${_userName ?? ''}님, 환영합니다.',
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
                      '이메일로 보내드린 6자 코드를 입력해주세요.',
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
                      length: 6,
                      onChanged: _onCodeChanged,
                      width: 320,
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
                    text: _isLoading ? '처리 중...' : '다음',
                    onPressed: (_verificationCode.length == 6 && !_isLoading)
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

// 개발 환경에서 SSL 인증서 검증 우회를 위한 클래스
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
