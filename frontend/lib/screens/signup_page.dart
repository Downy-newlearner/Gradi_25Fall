import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import '../widgets/back_button.dart' as custom;
import '../widgets/page_title.dart';
import '../widgets/labeled_input_field.dart';
import '../widgets/next_button.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _emailCodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // 유효성 검사 상태
  String? _idError;
  String? _emailError;
  String? _emailCodeError;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _isIdFieldError = false;
  bool _isEmailFieldError = false;
  bool _isEmailCodeFieldError = false;
  bool _isPasswordFieldError = false;
  bool _isConfirmPasswordFieldError = false;

  // API 호출 상태
  bool _isCheckingIdDuplicate = false;
  bool _isSendingEmailCode = false;
  bool _isIdDuplicateChecked = false;
  bool _isEmailVerified = false;
  bool _isEmailCodeEnabled = false;
  bool _isVerifyingEmailCode = false;

  // 비밀번호 정책 검사 결과
  List<String> _passwordPolicyErrors = [];
  String? _emailCodeSuccessMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _emailCodeController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleBack() {
    Navigator.pop(context);
  }

  // 이메일 형식 검증
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^.+@.+$');
    return emailRegex.hasMatch(email);
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
      _passwordError = null;
      _isPasswordFieldError = false;
    });

    // 비밀번호 확인 필드도 실시간으로 검사
    if (_confirmPasswordController.text.isNotEmpty) {
      _onConfirmPasswordChanged(_confirmPasswordController.text);
    }
  }

  // 실시간 비밀번호 확인 검사
  void _onConfirmPasswordChanged(String value) {
    setState(() {
      if (value.isNotEmpty && _passwordController.text != value) {
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
      _idError = null;
      _emailError = null;
      _emailCodeError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _isIdFieldError = false;
      _isEmailFieldError = false;
      _isEmailCodeFieldError = false;
      _isPasswordFieldError = false;
      _isConfirmPasswordFieldError = false;
      _passwordPolicyErrors = [];
    });
  }

  bool _validateInputs() {
    bool isValid = true;
    _clearErrors();

    // 이름 유효성 검사
    if (_nameController.text.trim().isEmpty) {
      // 이름은 별도 에러 메시지 없이 기본적으로 처리
      isValid = false;
    }

    // 아이디 유효성 검사
    if (_idController.text.trim().isEmpty) {
      setState(() {
        _idError = '아이디를 입력해주세요';
        _isIdFieldError = true;
      });
      isValid = false;
    } else if (!_isIdDuplicateChecked) {
      setState(() {
        _idError = '아이디 중복 확인을 해주세요';
        _isIdFieldError = true;
      });
      isValid = false;
    }

    // 이메일 유효성 검사
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _emailError = '이메일을 입력해주세요';
        _isEmailFieldError = true;
      });
      isValid = false;
    } else if (!_isValidEmail(_emailController.text.trim())) {
      setState(() {
        _emailError = '올바른 이메일 주소를 입력해주세요';
        _isEmailFieldError = true;
      });
      isValid = false;
    }

    // 이메일 인증 유효성 검사
    if (!_isEmailVerified) {
      setState(() {
        _emailCodeError = '이메일 인증을 완료해주세요';
        _isEmailCodeFieldError = true;
      });
      isValid = false;
    }

    // 비밀번호 유효성 검사
    if (_passwordController.text.trim().isEmpty) {
      setState(() {
        _passwordError = '비밀번호를 입력해주세요';
        _isPasswordFieldError = true;
      });
      isValid = false;
    } else {
      List<String> policyErrors = _validatePasswordPolicy(
        _passwordController.text,
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
        _confirmPasswordError = '비밀번호 확인을 입력해주세요';
        _isConfirmPasswordFieldError = true;
      });
      isValid = false;
    } else if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _confirmPasswordError = '입력된 비밀번호가 다릅니다';
        _isConfirmPasswordFieldError = true;
      });
      isValid = false;
    }

    return isValid;
  }

  // 아이디 중복 검사
  Future<void> _checkIdDuplicate() async {
    if (_idController.text.trim().isEmpty) {
      setState(() {
        _idError = '아이디를 입력해주세요';
        _isIdFieldError = true;
      });
      return;
    }

    setState(() {
      _isCheckingIdDuplicate = true;
      _idError = null;
      _isIdFieldError = false;
    });

    try {
      // TODO: 아이디 중복 검사 API 구현 필요
      // 임시로 1초 후 랜덤 결과 반환
      await Future.delayed(const Duration(seconds: 1));

      // TODO: 실제 API 구현 시 서버 응답 처리를 여기에 구현
      // 현재는 임시로 클라이언트 측에서 아이디 중복 검사 로직을 구현

      if (mounted) {
        setState(() {
          _isCheckingIdDuplicate = false;
          // 실제로는 서버 응답에 따라 결정
          _isIdDuplicateChecked = true; // 임시로 항상 사용 가능으로 설정
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingIdDuplicate = false;
          _idError = '중복 확인 중 오류가 발생했습니다';
          _isIdFieldError = true;
          _isIdDuplicateChecked = false;
        });
      }
    }
  }

  // 이메일 인증번호 발송
  Future<void> _sendEmailCode() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _emailError = '이메일을 입력해주세요';
        _isEmailFieldError = true;
      });
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      setState(() {
        _emailError = '올바른 이메일 주소를 입력해주세요';
        _isEmailFieldError = true;
      });
      return;
    }

    setState(() {
      _isSendingEmailCode = true;
      _emailError = null;
      _isEmailFieldError = false;
      _isEmailCodeEnabled = false;
      _emailCodeSuccessMessage = null;
    });

    try {
      HttpOverrides.global = _MyHttpOverrides();

      const String serverIp = '3.34.214.133';
      final String url = 'https://$serverIp/send-code/sign-up';
      final Map<String, String> requestData = {
        'email': _emailController.text.trim(),
      };

      developer.log('POST $url');
      developer.log('Request: $requestData');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (mounted) {
        setState(() {
          _isSendingEmailCode = false;
        });
      }
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _isEmailCodeEnabled = true;
            _isEmailVerified = false;
            _emailCodeController.clear();
            _emailError = null;
            _isEmailFieldError = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('인증번호가 발송되었습니다.')));
        } else {
          setState(() {
            _isEmailCodeEnabled = false;
            _emailError = '올바른 이메일인지 확인해주세요.';
            _isEmailFieldError = true;
          });
        }
      } else {
        setState(() {
          _isEmailCodeEnabled = false;
          _emailError = '올바른 이메일인지 확인해주세요.';
          _isEmailFieldError = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingEmailCode = false;
          _isEmailCodeEnabled = false;
          _emailError = '올바른 이메일인지 확인해주세요.';
          _isEmailFieldError = true;
        });
      }
      developer.log('Send email code error: $e');
    }
  }

  // 이메일 인증번호 확인
  Future<void> _verifyEmailCode() async {
    if (_emailCodeController.text.trim().isEmpty) {
      setState(() {
        _emailCodeError = '인증번호를 입력해주세요';
        _isEmailCodeFieldError = true;
      });
      return;
    }

    setState(() {
      _emailCodeError = null;
      _isEmailCodeFieldError = false;
    });

    try {
      HttpOverrides.global = _MyHttpOverrides();

      const String serverIp = '3.34.214.133';
      final String url = 'https://$serverIp/verify/sign-up';

      setState(() {
        _isVerifyingEmailCode = true;
        _emailCodeSuccessMessage = null;
      });

      final Map<String, String> requestData = {
        'email': _emailController.text.trim(),
        'code': _emailCodeController.text.trim(),
      };

      developer.log('POST $url');
      developer.log('Request: $requestData');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      developer.log('Response status: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (mounted) {
        setState(() {
          _isVerifyingEmailCode = false;
        });
      }
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _isEmailVerified = true;
            _isEmailCodeEnabled = false; // 입력 폼 비활성화 (값 유지)
            _emailCodeError = null;
            _isEmailCodeFieldError = false;
            _emailCodeSuccessMessage = '인증이 완료되었습니다.';
          });
        } else {
          setState(() {
            _isEmailVerified = false;
            _emailCodeError = '인증번호가 올바르지 않습니다';
            _isEmailCodeFieldError = true;
            _emailCodeSuccessMessage = null;
          });
        }
      } else {
        setState(() {
          _isEmailVerified = false;
          _emailCodeError = '인증번호가 올바르지 않습니다';
          _isEmailCodeFieldError = true;
          _emailCodeSuccessMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifyingEmailCode = false;
          _isEmailVerified = false;
          _emailCodeError = '인증번호 확인 중 오류가 발생했습니다';
          _isEmailCodeFieldError = true;
          _emailCodeSuccessMessage = null;
        });
      }
      developer.log('Verify email code error: $e');
    }
  }

  void _handleSignUp() {
    if (!_validateInputs()) {
      return;
    }

    // TODO: 회원가입 API 구현
    developer.log('SignUp - name: ${_nameController.text}');
    developer.log('SignUp - id: ${_idController.text}');
    developer.log('SignUp - email: ${_emailController.text}');
    developer.log('SignUp - phone: ${_phoneController.text}');
    developer.log('SignUp - password: ${_passwordController.text}');
    developer.log('SignUp - confirm: ${_confirmPasswordController.text}');
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      custom.CustomBackButton(onPressed: _handleBack),
                      const SizedBox(width: 20),
                      const PageTitle(text: '회원가입'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LabeledInputField(
                    label: '이름*',
                    placeholder: '이름을 입력해주세요',
                    controller: _nameController,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 24),
                  // 아이디 입력 필드와 중복 확인 버튼
                  Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Label
                            const Text(
                              '아이디*',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                height: 1.193,
                                color: Color(0xFF5C5C5C),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Input Field
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F3F3),
                                borderRadius: BorderRadius.circular(5),
                                border: _isIdFieldError
                                    ? Border.all(
                                        color: const Color(0xFFFF4258),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: TextField(
                                controller: _idController,
                                keyboardType: TextInputType.text,
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  height: 1.193,
                                  color: _isIdFieldError
                                      ? const Color(0xFFFF4258)
                                      : const Color(0xFFA0A0A0),
                                ),
                                decoration: InputDecoration(
                                  hintText: '아이디를 입력해주세요',
                                  hintStyle: const TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    height: 1.193,
                                    color: Color(0xFFA0A0A0),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 16,
                                  ),
                                ),
                                onChanged: (value) {
                                  // 아이디가 변경되면 중복 확인 상태 초기화
                                  if (_isIdDuplicateChecked) {
                                    setState(() {
                                      _isIdDuplicateChecked = false;
                                    });
                                  }
                                },
                              ),
                            ),

                            // Error Message
                            if (_isIdFieldError && _idError != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _idError!,
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

                      const SizedBox(width: 12),

                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 31),
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isCheckingIdDuplicate
                                  ? null
                                  : _checkIdDuplicate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isIdDuplicateChecked
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _isCheckingIdDuplicate
                                    ? '확인 중...'
                                    : _isIdDuplicateChecked
                                    ? '사용 가능'
                                    : '중복 확인',
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 이메일 입력 필드와 인증번호 발송 버튼
                  Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Label
                            const Text(
                              '이메일*',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                height: 1.193,
                                color: Color(0xFF5C5C5C),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Input Field
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F3F3),
                                borderRadius: BorderRadius.circular(5),
                                border: _isEmailFieldError
                                    ? Border.all(
                                        color: const Color(0xFFFF4258),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  height: 1.193,
                                  color: _isEmailFieldError
                                      ? const Color(0xFFFF4258)
                                      : const Color(0xFFA0A0A0),
                                ),
                                decoration: InputDecoration(
                                  hintText: '이메일 주소를 입력해주세요',
                                  hintStyle: const TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    height: 1.193,
                                    color: Color(0xFFA0A0A0),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 16,
                                  ),
                                ),
                                onChanged: (value) {
                                  // 이메일이 변경되면 인증 상태 초기화
                                  if (_isEmailVerified) {
                                    setState(() {
                                      _isEmailVerified = false;
                                      _emailCodeController.clear();
                                    });
                                  }
                                },
                              ),
                            ),

                            // Error Message
                            if (_isEmailFieldError && _emailError != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _emailError!,
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

                      const SizedBox(width: 12),

                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 31),
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSendingEmailCode
                                  ? null
                                  : _sendEmailCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _isSendingEmailCode ? '발송 중...' : '인증번호 발송',
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 인증번호 입력 필드 + 확인 버튼
                  Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: Container(
                          decoration: BoxDecoration(
                            border: _isEmailCodeFieldError
                                ? Border.all(
                                    color: const Color(0xFFFF4258),
                                    width: 1,
                                  )
                                : Border.all(
                                    color: const Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _emailCodeController,
                            enabled: _isEmailCodeEnabled || _isEmailVerified,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '인증번호를 입력해주세요',
                              hintStyle: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF9CA3AF),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              errorText: _emailCodeError,
                            ),
                            onSubmitted: (value) {
                              if (value.isNotEmpty &&
                                  (_isEmailCodeEnabled || _isEmailVerified)) {
                                _verifyEmailCode();
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 0),
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  (!_isEmailCodeEnabled ||
                                      _isVerifyingEmailCode)
                                  ? null
                                  : _verifyEmailCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _isVerifyingEmailCode ? '확인 중...' : '인증번호 확인',
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_emailCodeSuccessMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _emailCodeSuccessMessage!,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.33,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  LabeledInputField(
                    label: '휴대전화*',
                    placeholder: '전화번호를 입력해주세요',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  // 비밀번호 입력 필드와 정책 에러 표시
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabeledInputField(
                        label: '비밀번호*',
                        placeholder: '비밀번호를 입력해주세요',
                        controller: _passwordController,
                        keyboardType: TextInputType.visiblePassword,
                        obscureText: true,
                        isError:
                            _isPasswordFieldError ||
                            _passwordPolicyErrors.isNotEmpty,
                        errorMessage: _passwordError,
                        onChanged: _onPasswordChanged,
                      ),
                      _buildPasswordPolicyErrors(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  LabeledInputField(
                    label: '비밀번호 확인*',
                    placeholder: '비밀번호를 다시 입력해주세요',
                    controller: _confirmPasswordController,
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                    isError: _isConfirmPasswordFieldError,
                    errorMessage: _confirmPasswordError,
                    onChanged: _onConfirmPasswordChanged,
                  ),
                  const SizedBox(height: 20),
                  NextButton(text: '다음', onPressed: _handleSignUp),
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

// 개발 환경에서 SSL 인증서 검증 우회를 위한 클래스 (프로덕션에서는 제거)
class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
