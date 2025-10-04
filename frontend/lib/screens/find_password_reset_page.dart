import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import '../widgets/back_button.dart' as custom;
import '../widgets/page_title.dart';
import '../widgets/labeled_input_field.dart';
import '../widgets/next_button.dart';

class FindPasswordResetPage extends StatefulWidget {
  const FindPasswordResetPage({super.key});

  @override
  State<FindPasswordResetPage> createState() => _FindPasswordResetPageState();
}

class _FindPasswordResetPageState extends State<FindPasswordResetPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // 유효성 검사 상태
  String? _newPasswordError;
  String? _confirmPasswordError;
  bool _isNewPasswordFieldError = false;
  bool _isConfirmPasswordFieldError = false;
  bool _isLoading = false;

  // 비밀번호 정책 검사 결과
  List<String> _passwordPolicyErrors = [];

  // 전달받은 사용자 정보
  String? _userId;

  @override
  void initState() {
    super.initState();
    // 전달받은 arguments 처리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (arguments != null) {
        setState(() {
          _userId = arguments['userId'];
        });
      }
    });
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleBack() {
    // 비밀번호 찾기 페이지로 이동 (입력폼은 모두 공백 상태)
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/find-password',
      (route) => false,
    );
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
  void _onNewPasswordChanged(String value) {
    setState(() {
      _passwordPolicyErrors = _validatePasswordPolicy(value);
      _newPasswordError = null;
      _isNewPasswordFieldError = false;
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

  void _clearErrors() {
    setState(() {
      _newPasswordError = null;
      _confirmPasswordError = null;
      _isNewPasswordFieldError = false;
      _isConfirmPasswordFieldError = false;
      _passwordPolicyErrors = [];
    });
  }

  bool _validateInputs() {
    bool isValid = true;
    _clearErrors();

    // 새 비밀번호 유효성 검사
    if (_newPasswordController.text.trim().isEmpty) {
      setState(() {
        _newPasswordError = '변경할 비밀번호를 입력해주세요';
        _isNewPasswordFieldError = true;
      });
      isValid = false;
    } else {
      // 비밀번호 정책 검사
      List<String> policyErrors = _validatePasswordPolicy(
        _newPasswordController.text,
      );
      if (policyErrors.isNotEmpty) {
        setState(() {
          _passwordPolicyErrors = policyErrors;
        });
        isValid = false;
      }
    }

    // 비밀번호 확인 유효성 검사
    if (_confirmPasswordController.text.trim().isEmpty) {
      setState(() {
        _isConfirmPasswordFieldError = true; // 테두리만 빨간색으로, 에러 메시지는 표시하지 않음
      });
      isValid = false;
    } else if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _confirmPasswordError = '입력된 비밀번호가 다릅니다';
        _isConfirmPasswordFieldError = true;
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
      const String url = 'https://$serverIp/change/reset_password';

      // TODO: JSON 형식 미정 - 서버 API 스펙에 맞게 수정 필요
      // 요청 데이터 준비
      final Map<String, String> requestData = {
        'account_id': _userId ?? '',
        'new_password': _newPasswordController.text.trim(),
      };

      developer.log('Password reset attempted for user: $_userId');
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

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (!mounted) return;

      // 응답 처리
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        developer.log(
          'Password reset successful. Response data: $responseData',
        );

        // success 컬럼이 true인지 확인
        if (responseData['success'] == true) {
          // 성공 페이지로 이동
          Navigator.pushNamed(context, '/password-reset-success');
        } else {
          // success가 false인 경우 에러 처리
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('비밀번호 변경에 실패했습니다.')));
        }
      } else if (response.statusCode == 500) {
        // TODO: 500 에러 처리 구현 필요 - 미래에 구현 요청됨
        developer.log('Password reset failed with 500 error');
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('서버 오류가 발생했습니다.')));
      } else {
        // 기타 에러 처리
        developer.log(
          'Password reset failed with status: ${response.statusCode}',
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('비밀번호 변경 실패: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      developer.log('Password reset error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('네트워크 오류: $e')));
    }
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
                const PageTitle(text: '비밀번호 변경'),

                const SizedBox(
                  height: 48,
                ), // Space between title and input fields
                // New Password Input Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabeledInputField(
                        label: '변경할 비밀번호*',
                        placeholder: '비밀번호를 입력해주세요',
                        controller: _newPasswordController,
                        obscureText: true,
                        keyboardType: TextInputType.visiblePassword,
                        isError:
                            _isNewPasswordFieldError ||
                            _passwordPolicyErrors.isNotEmpty,
                        errorMessage: _newPasswordError,
                        onChanged: _onNewPasswordChanged,
                      ),
                      _buildPasswordPolicyErrors(),
                    ],
                  ),
                ),

                const SizedBox(height: 24), // Space between password fields
                // Confirm Password Input Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: LabeledInputField(
                    label: '변경할 비밀번호 확인*',
                    placeholder: '비밀번호를 다시 입력해주세요',
                    controller: _confirmPasswordController,
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    isError: _isConfirmPasswordFieldError,
                    errorMessage: _confirmPasswordError,
                    onChanged: _onConfirmPasswordChanged,
                  ),
                ),

                const SizedBox(
                  height: 140,
                ), // Space between input fields and next button
                // Next Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: NextButton(
                    text: _isLoading ? '처리 중...' : '다음',
                    onPressed: _isLoading ? null : _handleNext,
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
