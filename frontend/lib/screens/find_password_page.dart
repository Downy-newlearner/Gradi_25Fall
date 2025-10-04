import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import '../widgets/back_button.dart' as custom;
import '../widgets/page_title.dart';
import '../widgets/labeled_input_field.dart';
import '../widgets/next_button.dart';

class FindPasswordPage extends StatefulWidget {
  const FindPasswordPage({super.key});

  @override
  State<FindPasswordPage> createState() => _FindPasswordPageState();
}

class _FindPasswordPageState extends State<FindPasswordPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  // 유효성 검사 상태
  String? _nameError;
  String? _emailError;
  String? _idError;
  bool _isNameFieldError = false;
  bool _isEmailFieldError = false;
  bool _isIdFieldError = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _idController.dispose();
    super.dispose();
  }

  void _handleBack() {
    Navigator.pop(context);
  }

  bool _isValidEmail(String email) {
    // 이메일 형식 검증: @가 포함되고 앞뒤로 최소 한 글자 이상
    final emailRegex = RegExp(r'^.+@.+$');
    return emailRegex.hasMatch(email);
  }

  void _clearErrors() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _idError = null;
      _isNameFieldError = false;
      _isEmailFieldError = false;
      _isIdFieldError = false;
    });
  }

  bool _validateInputs() {
    bool isValid = true;
    _clearErrors();

    // 이름 유효성 검사
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _nameError = '이름을 입력해주세요.';
        _isNameFieldError = true;
      });
      isValid = false;
    }

    // 이메일 유효성 검사
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _emailError = '이메일을 입력해주세요.';
        _isEmailFieldError = true;
      });
      isValid = false;
    } else if (!_isValidEmail(_emailController.text.trim())) {
      setState(() {
        _emailError = '올바른 주소를 입력해주세요';
        _isEmailFieldError = true;
      });
      isValid = false;
    }

    // 아이디 유효성 검사
    if (_idController.text.trim().isEmpty) {
      setState(() {
        _idError = '아이디를 입력해주세요.';
        _isIdFieldError = true;
      });
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleNext() async {
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
      const String url = 'https://$serverIp/send-code/find_account';

      // 요청 데이터 준비
      final Map<String, String> requestData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'account_id': _idController.text.trim(),
      };

      developer.log(
        'Find Password attempted with name: ${_nameController.text.trim()}',
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

      // 응답 처리
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        developer.log(
          'Find Password request successful. Response data: $responseData',
        );

        // success 컬럼이 true인지 확인
        if (responseData['success'] == true) {
          // 성공 시 비밀번호 인증 페이지로 이동
          Navigator.pushNamed(
            context,
            '/find-password-verification',
            arguments: {
              'userName': _nameController.text.trim(),
              'userId': _idController.text.trim(),
              'email': _emailController.text.trim(),
            },
          );
        } else {
          // success가 false인 경우 에러 페이지로 이동
          developer.log('Find Password failed: success is false');
          Navigator.pushNamed(context, '/find-password-error');
        }
      } else if (response.statusCode == 500) {
        // 500 에러 시 에러 페이지로 이동
        developer.log('Find Password failed: User not found (500 error)');
        Navigator.pushNamed(context, '/find-password-error');
      } else {
        // 기타 에러
        developer.log(
          'Find Password failed with status: ${response.statusCode}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류가 발생했습니다: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      developer.log('Find Password error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('네트워크 오류: $e')));
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
                      const PageTitle(text: '비밀번호 찾기'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LabeledInputField(
                    label: '이름*',
                    placeholder: '이름을 입력해주세요',
                    controller: _nameController,
                    keyboardType: TextInputType.text,
                    isError: _isNameFieldError,
                    errorMessage: _nameError,
                  ),
                  const SizedBox(height: 24),
                  LabeledInputField(
                    label: '이메일*',
                    placeholder: '이메일 주소를 입력해주세요',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    isError: _isEmailFieldError,
                    errorMessage: _emailError,
                  ),
                  const SizedBox(height: 24),
                  LabeledInputField(
                    label: '아이디*',
                    placeholder: '아이디를 입력해주세요',
                    controller: _idController,
                    keyboardType: TextInputType.text,
                    isError: _isIdFieldError,
                    errorMessage: _idError,
                  ),
                  const SizedBox(height: 20),
                  NextButton(
                    text: _isLoading ? '처리 중...' : '다음',
                    onPressed: _isLoading ? null : _handleNext,
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
