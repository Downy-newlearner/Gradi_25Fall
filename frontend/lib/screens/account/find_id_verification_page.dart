import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import '../../widgets/back_button.dart' as custom;
import '../../widgets/page_title.dart';
import '../../widgets/verification_code_input.dart';
import '../../widgets/next_button.dart';
import '../../config/api_config.dart';

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
      developer.log(
        'FindIDVerificationPage - userName: $_userName, email: $_email',
      );
      developer.log('FindIDVerificationPage - args: $args');
    } else {
      developer.log('FindIDVerificationPage - No arguments received');
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

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // 개발 환경에서 SSL 인증서 검증 우회 (프로덕션에서는 제거 필요)
      HttpOverrides.global = MyHttpOverrides();

      // 서버 IP 설정 (필요에 따라 변경)
      final url = ApiConfig.getVerifyFindAccountUri();

      // 요청 데이터 준비
      final Map<String, String> requestData = {
        'email': _email ?? '',
        'code': _verificationCode.toString(),
      };

      developer.log('Sending verification request: $requestData');
      developer.log('Request URL: $url');
      developer.log('Email before request: $_email');
      developer.log('Verification code: $_verificationCode');
      developer.log(
        'Request headers: {\'Content-Type\': \'application/json\'}',
      );

      // API 호출
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response headers: ${response.headers}');
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
    if (mounted) {
      setState(() {
        _verificationCode = code;
      });
    }
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
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Back Button and Title
                  Row(
                    children: [
                      custom.CustomBackButton(onPressed: _handleBack),
                      const SizedBox(width: 20),
                      const PageTitle(text: '아이디 찾기'),
                    ],
                  ),

                  const SizedBox(height: 20),
                  // Welcome Message
                  Text(
                    '${_userName ?? ''}님, 환영합니다.',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5C5C5C),
                      height: 1.193,
                    ),
                  ),

                  const SizedBox(height: 7),
                  // Instructions
                  const Text(
                    '이메일로 보내드린 6자 코드를 입력해주세요.',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5C5C5C),
                      height: 1.193,
                    ),
                  ),

                  const SizedBox(height: 24),
                  // Verification Code Input
                  VerificationCodeInput(
                    length: 6,
                    onChanged: _onCodeChanged,
                    width: 320,
                    height: 50,
                  ),

                  const SizedBox(height: 13),
                  // Resend Code Link
                  GestureDetector(
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

                  const SizedBox(height: 161),
                  // Next Button
                  NextButton(
                    text: _isLoading ? '처리 중...' : '다음',
                    onPressed: (_verificationCode.length == 6 && !_isLoading)
                        ? _handleNext
                        : null,
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

// 개발 환경에서 SSL 인증서 검증 우회를 위한 클래스
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
