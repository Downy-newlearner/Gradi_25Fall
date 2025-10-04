import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
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
  bool _isLoading = false;
  String? _email;
  String? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // arguments에서 데이터 추출
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _email = args['email'] as String?;
      _userId = args['userId'] as String?;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleBack() {
    Navigator.pop(context);
  }

  void _handleNext() async {
    if (_codeController.text.length != 6) {
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
      const String url = 'https://$serverIp/verify/reset_password';

      // 요청 데이터 준비
      final Map<String, String> requestData = {
        'email': _email ?? '',
        'code': _codeController.text,
      };

      developer.log('Sending password verification request: $requestData');

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
          // 성공 시 비밀번호 재설정 페이지로 이동
          Navigator.pushNamed(
            context,
            '/reset-password',
            arguments: {'userId': _userId, 'email': _email},
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
      developer.log('Error during password verification: $e');
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
    // TODO: Implement resend verification code
    developer.log('Resending verification code...');
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
                    '이메일로 보내드린 6자 코드를 입력해주세요.',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF5C5C5C),
                    ),
                  ),
                  const SizedBox(height: 24),
                  VerificationCodeInput(
                    length: 6,
                    onChanged: (code) {
                      _codeController.text = code;
                    },
                    width: 320,
                    height: 50,
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
                  NextButton(
                    text: _isLoading ? '처리 중...' : '다음',
                    onPressed: (_codeController.text.length == 6 && !_isLoading)
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
