import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import '../widgets/back_button.dart' as custom;
import '../widgets/page_title.dart';
import '../widgets/labeled_input_field.dart';
import '../widgets/next_button.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  String? _userId;
  String? _email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // arguments에서 데이터 추출
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _userId = args['userId'] as String?;
      _email = args['email'] as String?;
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleBack() {
    Navigator.pop(context);
  }

  void _handleResetPassword() async {
    // 기본 유효성 검사
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호가 일치하지 않습니다.'),
          backgroundColor: Color(0xFFFF4258),
        ),
      );
      return;
    }

    if (_newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호를 입력해주세요.'),
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
      const String url = 'https://$serverIp/change-password';

      // 요청 데이터 준비
      final Map<String, String> requestData = {
        'user_id': _userId ?? '',
        'email': _email ?? '',
        'new_password': _newPasswordController.text,
      };

      developer.log('Sending password change request: $requestData');

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
          // 성공 시 로그인 페이지로 이동
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        } else {
          // 실패
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('비밀번호 변경에 실패했습니다.'),
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
      developer.log('Error during password change: $e');
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      custom.CustomBackButton(onPressed: _handleBack),
                      const SizedBox(width: 20),
                      const PageTitle(text: '비밀번호 재설정'),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    '새로운 비밀번호를 설정해주세요.',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Color(0xFF5C5C5C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '안전한 비밀번호로 계정을 보호하세요.',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Color(0xFFA0A0A0),
                    ),
                  ),
                  const SizedBox(height: 40),
                  LabeledInputField(
                    label: '새 비밀번호*',
                    placeholder: '새 비밀번호를 입력해주세요',
                    controller: _newPasswordController,
                    keyboardType: TextInputType.text,
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  LabeledInputField(
                    label: '새 비밀번호 확인*',
                    placeholder: '새 비밀번호를 다시 입력해주세요',
                    controller: _confirmPasswordController,
                    keyboardType: TextInputType.text,
                    obscureText: true,
                  ),
                  const SizedBox(height: 40),
                  NextButton(
                    text: _isLoading ? '처리 중...' : '확인',
                    onPressed: _isLoading ? null : _handleResetPassword,
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
