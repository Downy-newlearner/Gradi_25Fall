import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import '../../widgets/back_button.dart' as custom;
import '../../widgets/page_title.dart';
import '../../widgets/next_button.dart';
import '../../widgets/input_field.dart';

class PasswordResetFormPage extends StatefulWidget {
  const PasswordResetFormPage({super.key});

  @override
  State<PasswordResetFormPage> createState() => _PasswordResetFormPageState();
}

class _PasswordResetFormPageState extends State<PasswordResetFormPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  String? _token;

  // 비밀번호 정책 검사 결과
  List<String> _passwordPolicyErrors = [];
  String? _confirmPasswordError;
  bool _isConfirmPasswordFieldError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // arguments에서 token 추출
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _token = args['token'] as String?;
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleBack() {
    // 로그인 페이지로 이동
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  // 비밀번호 정책 검사
  List<String> _validatePasswordPolicy(String password) {
    List<String> errors = [];

    if (password.length < 8) {
      errors.add('8자 이상이어야 합니다');
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      errors.add('대문자를 포함해야 합니다');
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      errors.add('소문자를 포함해야 합니다');
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      errors.add('숫자를 포함해야 합니다');
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      errors.add('특수문자를 포함해야 합니다');
    }

    return errors;
  }

  // 실시간 비밀번호 유효성 검사
  void _onPasswordChanged(String value) {
    setState(() {
      _passwordPolicyErrors = _validatePasswordPolicy(value);
    });

    // 비밀번호 확인 필드도 실시간으로 검사
    if (_confirmPasswordController.text.isNotEmpty) {
      _onConfirmPasswordChanged(_confirmPasswordController.text);
    }
  }

  // 실시간 비밀번호 확인 검사
  void _onConfirmPasswordChanged(String value) {
    setState(() {
      if (value.isNotEmpty && _newPasswordController.text != value) {
        _confirmPasswordError = '입력된 비밀번호가 다릅니다';
        _isConfirmPasswordFieldError = true;
      } else {
        _confirmPasswordError = null;
        _isConfirmPasswordFieldError = false;
      }
    });
  }

  // 비밀번호 정책 에러 표시 위젯
  Widget _buildPasswordPolicyErrors() {
    if (_passwordPolicyErrors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _passwordPolicyErrors.map((error) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              '• $error',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.33,
                color: Color(0xFFFF4258),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _handleResetPassword() async {
    // 입력값 검증
    if (_newPasswordController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('새 비밀번호를 입력해주세요.'),
          backgroundColor: Color(0xFFFF4258),
        ),
      );
      return;
    }

    // 비밀번호 정책 검사
    List<String> policyErrors = _validatePasswordPolicy(
      _newPasswordController.text,
    );
    if (policyErrors.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호 정책을 만족해야 합니다.'),
          backgroundColor: Color(0xFFFF4258),
        ),
      );
      return;
    }

    if (_confirmPasswordController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호 확인을 입력해주세요.'),
          backgroundColor: Color(0xFFFF4258),
        ),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호가 일치하지 않습니다.'),
          backgroundColor: Color(0xFFFF4258),
        ),
      );
      return;
    }

    if (_token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('인증 토큰이 없습니다. 다시 시도해주세요.'),
          backgroundColor: Color(0xFFFF4258),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 개발 환경에서 SSL 인증서 검증 우회
      HttpOverrides.global = MyHttpOverrides();

      const String serverIp = '3.34.214.133';
      const String url = 'https://$serverIp/users/reset-password';

      // 요청 데이터 준비
      final Map<String, String> requestData = {
        'token': _token!,
        'new_password': _newPasswordController.text.trim(),
      };

      developer.log('Sending password reset request: $requestData');

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
          // 성공 시 성공 페이지로 이동
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/password-reset-success',
              (route) => false,
            );
          }
        } else {
          // 실패
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('비밀번호 변경에 실패했습니다. 다시 시도해주세요.'),
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
      developer.log('Error during password reset: $e');
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24), // Top spacing
                // Back Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: custom.CustomBackButton(onPressed: _handleBack),
                ),

                const SizedBox(height: 7),
                // Page Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: PageTitle(text: '비밀번호 변경', textAlign: TextAlign.left),
                ),

                const SizedBox(height: 48),
                // Instruction Message
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    '새 비밀번호를 입력해주세요.',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      height: 1.193359375,
                      color: Color(0xFF5C5C5C),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                // New Password Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InputField(
                        placeholder: '새 비밀번호',
                        controller: _newPasswordController,
                        obscureText: true,
                        onChanged: _onPasswordChanged,
                        isError: _passwordPolicyErrors.isNotEmpty,
                      ),
                      _buildPasswordPolicyErrors(),
                    ],
                  ),
                ),

                const SizedBox(height: 20), // Space between input fields
                // Confirm Password Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InputField(
                        placeholder: '비밀번호 확인',
                        controller: _confirmPasswordController,
                        obscureText: true,
                        onChanged: _onConfirmPasswordChanged,
                        isError: _isConfirmPasswordFieldError,
                      ),
                      if (_confirmPasswordError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _confirmPasswordError!,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.33,
                            color: Color(0xFFFF4258),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                // Reset Password Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: NextButton(
                    text: _isLoading ? '처리 중...' : '비밀번호 변경',
                    onPressed: _isLoading ? null : _handleResetPassword,
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
