import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import '../widgets/app_logo.dart';
import '../widgets/input_field.dart';
import '../widgets/login_button.dart';
import '../widgets/sns_button.dart';
import '../widgets/links_section.dart';
import '../widgets/sns_divider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 유효성 검사 상태
  bool _isUsernameFieldError = false;
  bool _isPasswordFieldError = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _isUsernameFieldError = false;
      _isPasswordFieldError = false;
    });
  }

  bool _validateInputs() {
    bool isValid = true;
    _clearErrors();

    // 아이디 유효성 검사
    if (_usernameController.text.trim().isEmpty) {
      setState(() {
        _isUsernameFieldError = true;
      });
      isValid = false;
    }

    // 비밀번호 유효성 검사
    if (_passwordController.text.trim().isEmpty) {
      setState(() {
        _isPasswordFieldError = true;
      });
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleLogin() async {
    // 입력 값 검증
    if (!_validateInputs()) {
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
      const String url = 'https://$serverIp/sign-in';

      // 이미지 JSON 형식에 맞춰 요청 데이터 준비
      final Map<String, String> requestData = {
        'account_id': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
      };

      developer.log(
        'Login attempted with username: ${_usernameController.text.trim()}',
      );
      developer.log('Sending POST request to: $url');
      developer.log('Request data: $requestData');

      // HTTP POST 요청
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // TODO: 응답 처리 구현 필요 - 미래에 구현 요청됨
      // 200 응답, 500 응답 등의 처리를 여기에 구현해야 함
      developer.log('Response received - processing logic to be implemented');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      developer.log('Login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('네트워크 오류: $e')));
      }
    }
  }

  void _handleKakaoLogin() {
    // Handle Kakao login logic here
    developer.log('Kakao login attempted');
  }

  void _handleGoogleLogin() {
    // Handle Google login logic here
    developer.log('Google login attempted');
  }

  void _handleSignUp() {
    Navigator.pushNamed(context, '/signup');
  }

  void _handleFindID() {
    Navigator.pushNamed(context, '/find-id');
  }

  void _handleFindPW() {
    Navigator.pushNamed(context, '/find-password');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60), // Top spacing
                  // App Logo
                  const AppLogo(),

                  const SizedBox(
                    height: 80,
                  ), // Space between logo and input fields
                  // Input Fields
                  SizedBox(
                    width: 342,
                    child: Column(
                      children: [
                        // Username Input
                        InputField(
                          placeholder: '아이디',
                          controller: _usernameController,
                          keyboardType: TextInputType.text,
                          isError: _isUsernameFieldError,
                        ),

                        const SizedBox(height: 20),

                        // Password Input
                        InputField(
                          placeholder: '비밀번호',
                          controller: _passwordController,
                          obscureText: true,
                          isError: _isPasswordFieldError,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 35,
                  ), // Space between input fields and login button
                  // Login Button
                  LoginButton(
                    text: _isLoading ? '로그인 중...' : '로그인',
                    onPressed: _isLoading ? null : _handleLogin,
                  ),

                  const SizedBox(
                    height: 40,
                  ), // Space between login button and links
                  // Links Section
                  LinksSection(
                    onSignUp: _handleSignUp,
                    onFindID: _handleFindID,
                    onFindPW: _handleFindPW,
                  ),

                  const SizedBox(
                    height: 40,
                  ), // Space between links and SNS divider
                  // SNS Divider
                  const SNSDivider(),

                  const SizedBox(
                    height: 30,
                  ), // Space between divider and SNS buttons
                  // SNS Buttons
                  SizedBox(
                    width: 123,
                    height: 50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Kakao Button
                        SNSButton(
                          provider: SNSProvider.kakao,
                          onPressed: _handleKakaoLogin,
                        ),

                        // Google Button
                        SNSButton(
                          provider: SNSProvider.google,
                          onPressed: _handleGoogleLogin,
                        ),
                      ],
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

// 개발 환경에서 SSL 인증서 검증 우회를 위한 클래스
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
