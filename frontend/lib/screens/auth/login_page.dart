import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import '../../widgets/app_logo.dart';
import '../../widgets/input_field.dart';
import '../../widgets/login_button.dart';
import '../../widgets/sns_button.dart';
import '../../widgets/links_section.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../widgets/sns_divider.dart';
import '../../config/api_config.dart';

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

  // 자동 로그인 및 아이디 저장 설정
  bool _isAutoLoginEnabled = false;
  bool _isSaveAccountIdEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 저장된 설정 및 아이디 로드
  Future<void> _loadSettings() async {
    final authService = AuthService();

    // 저장된 설정 로드
    final autoLoginEnabled = await authService.isAutoLoginEnabled();
    final saveAccountIdEnabled = await authService.isSaveAccountIdEnabled();

    // 저장된 아이디 로드
    final savedAccountId = await authService.getSavedAccountId();

    setState(() {
      _isAutoLoginEnabled = autoLoginEnabled;
      _isSaveAccountIdEnabled = saveAccountIdEnabled;
      if (savedAccountId != null && savedAccountId.isNotEmpty) {
        _usernameController.text = savedAccountId;
      }
    });
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

      // API URL (ApiConfig에서 중앙 관리)
      final url = ApiConfig.getSignInUri();

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
        url,
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
        try {
          final responseData = json.decode(response.body);

          if (responseData['accessToken'] != null &&
              responseData['refreshToken'] != null) {
            // 토큰 저장
            final accessToken = responseData['accessToken'];
            final refreshToken = responseData['refreshToken'];

            // AuthService를 사용하여 토큰 저장
            final authService = AuthService();

            // 자동 로그인 설정 저장
            await authService.setAutoLogin(_isAutoLoginEnabled);

            // 아이디 저장 설정에 따라 처리
            if (_isSaveAccountIdEnabled) {
              await authService.setSaveAccountId(true);
              await authService.saveAccountId(_usernameController.text.trim());
            } else {
              await authService.setSaveAccountId(false);
              await authService.clearSavedAccountId();
            }

            // 로그인 성공 시 항상 토큰 저장 (현재 세션 유지)
            // 자동 로그인 설정은 다음 앱 시작 시에만 영향
            await authService.saveAccessToken(accessToken);
            await authService.saveRefreshToken(refreshToken);

            developer.log('Login successful - tokens received and saved');
            developer.log('Access Token: ${accessToken.substring(0, 20)}...');
            developer.log('Refresh Token: ${refreshToken.substring(0, 20)}...');
            developer.log('Auto login enabled: $_isAutoLoginEnabled');
            developer.log('Save account ID enabled: $_isSaveAccountIdEnabled');

            // 사용자 정보 가져오기
            try {
              await UserService().fetchUserFromServer();
              developer.log('User info fetched successfully after login');
            } catch (e) {
              developer.log('Failed to fetch user info after login: $e');
              // 사용자 정보 가져오기 실패해도 로그인은 성공으로 처리
            }

            // 메인 네비게이션 화면으로 이동
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            }
          } else {
            // 토큰이 없는 경우
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('로그인 응답에 토큰이 없습니다')));
            }
          }
        } catch (e) {
          developer.log('JSON parsing error: $e');
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('서버 응답을 처리할 수 없습니다')));
          }
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // 인증 실패
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('아이디 또는 비밀번호가 올바르지 않습니다')),
          );
        }
      } else {
        // 기타 오류
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('서버 오류: ${response.statusCode}')),
          );
        }
      }
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
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    constraints: const BoxConstraints(
                      maxWidth: 400,
                      minWidth: 300,
                    ),
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
                    height: 20,
                  ), // Space between login button and checkboxes
                  // 자동 로그인 및 아이디 저장 체크박스
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    constraints: const BoxConstraints(
                      maxWidth: 400,
                      minWidth: 300,
                    ),
                    child: Column(
                      children: [
                        // 자동 로그인 체크박스
                        Row(
                          children: [
                            Checkbox(
                              value: _isAutoLoginEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _isAutoLoginEnabled = value ?? false;
                                });
                              },
                              activeColor: const Color(0xFFAC5BF8),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isAutoLoginEnabled = !_isAutoLoginEnabled;
                                });
                              },
                              child: const Text(
                                '자동 로그인',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // 아이디 저장 체크박스
                        Row(
                          children: [
                            Checkbox(
                              value: _isSaveAccountIdEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _isSaveAccountIdEnabled = value ?? false;
                                });
                              },
                              activeColor: const Color(0xFFAC5BF8),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSaveAccountIdEnabled =
                                      !_isSaveAccountIdEnabled;
                                });
                              },
                              child: const Text(
                                '아이디 저장',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ), // Space between checkboxes and links
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
                  Container(
                    constraints: const BoxConstraints(
                      maxWidth: 200,
                      minWidth: 150,
                    ),
                    height: 50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Kakao Button
                        SNSButton(
                          provider: SNSProvider.kakao,
                          onPressed: _handleKakaoLogin,
                        ),

                        const SizedBox(width: 20), // 버튼 간격
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
