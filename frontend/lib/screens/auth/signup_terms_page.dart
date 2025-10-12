import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import '../../widgets/back_button.dart' as custom;
import '../../widgets/page_title.dart';
import '../../widgets/next_button.dart';

class SignUpTermsPage extends StatefulWidget {
  const SignUpTermsPage({super.key});

  @override
  State<SignUpTermsPage> createState() => _SignUpTermsPageState();
}

class _SignUpTermsPageState extends State<SignUpTermsPage> {
  bool _isAllTermsAgreed = false;
  bool _isRequiredTermsAgreed = false;
  bool _isMarketingTermsAgreed = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // 회원가입 정보 받기
    final Map<String, dynamic> signupData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

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
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.075,
              ),
              child: Column(
                children: [
                  Container(height: MediaQuery.of(context).size.height * 0.021),
                  Row(
                    children: [
                      custom.CustomBackButton(
                        onPressed: () => Navigator.pop(context),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.05,
                      ),
                      const PageTitle(text: '권한 동의'),
                    ],
                  ),
                  Container(height: MediaQuery.of(context).size.height * 0.04),

                  // 전체 동의 체크박스
                  _buildAllTermsCheckbox(),
                  Container(height: MediaQuery.of(context).size.height * 0.02),

                  // 구분선
                  Container(height: 1, color: const Color(0xFFE5E7EB)),
                  Container(height: MediaQuery.of(context).size.height * 0.02),

                  // 필수 약관들
                  _buildRequiredTerms(),
                  Container(height: MediaQuery.of(context).size.height * 0.03),

                  // 선택 약관
                  _buildOptionalTerms(),
                  Container(height: MediaQuery.of(context).size.height * 0.04),

                  // 완료 버튼
                  NextButton(
                    text: _isLoading ? '가입 중...' : '완료',
                    onPressed: (_isRequiredTermsAgreed && !_isLoading)
                        ? () => _handleComplete(signupData)
                        : null,
                  ),
                  Container(height: MediaQuery.of(context).size.height * 0.075),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllTermsCheckbox() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isAllTermsAgreed = !_isAllTermsAgreed;
          _isRequiredTermsAgreed = _isAllTermsAgreed;
          _isMarketingTermsAgreed = _isAllTermsAgreed;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.015,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(width: MediaQuery.of(context).size.width * 0.048),
            Container(
              width: MediaQuery.of(context).size.width * 0.06,
              height: MediaQuery.of(context).size.width * 0.06,
              decoration: BoxDecoration(
                color: _isAllTermsAgreed
                    ? const Color(0xFF6366F1)
                    : Colors.white,
                border: Border.all(
                  color: _isAllTermsAgreed
                      ? const Color(0xFF6366F1)
                      : const Color(0xFFE5E7EB),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _isAllTermsAgreed
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            Container(width: MediaQuery.of(context).size.width * 0.04),
            const Expanded(
              child: Text(
                '전체 동의',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequiredTerms() {
    return Column(
      children: [
        _buildTermsItem(
          title: '서비스 이용약관',
          isRequired: true,
          isChecked: _isRequiredTermsAgreed,
          onChanged: (value) {
            setState(() {
              _isRequiredTermsAgreed = value;
              _updateAllTermsState();
            });
          },
        ),
        Container(height: MediaQuery.of(context).size.height * 0.02),
        _buildTermsItem(
          title: '개인정보 처리방침',
          isRequired: true,
          isChecked: _isRequiredTermsAgreed,
          onChanged: (value) {
            setState(() {
              _isRequiredTermsAgreed = value;
              _updateAllTermsState();
            });
          },
        ),
      ],
    );
  }

  Widget _buildOptionalTerms() {
    return _buildTermsItem(
      title: '마케팅 정보 수신 동의',
      isRequired: false,
      isChecked: _isMarketingTermsAgreed,
      onChanged: (value) {
        setState(() {
          _isMarketingTermsAgreed = value;
          _updateAllTermsState();
        });
      },
    );
  }

  Widget _buildTermsItem({
    required String title,
    required bool isRequired,
    required bool isChecked,
    required Function(bool) onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!isChecked),
      child: Row(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.06,
            height: MediaQuery.of(context).size.width * 0.06,
            decoration: BoxDecoration(
              color: isChecked ? const Color(0xFF6366F1) : Colors.white,
              border: Border.all(
                color: isChecked
                    ? const Color(0xFF6366F1)
                    : const Color(0xFFE5E7EB),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: isChecked
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
          Container(width: MediaQuery.of(context).size.width * 0.04),
          Expanded(
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                if (isRequired) ...[
                  Container(width: MediaQuery.of(context).size.width * 0.02),
                  const Text(
                    '(필수)',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFF4258),
                    ),
                  ),
                ],
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateAllTermsState() {
    _isAllTermsAgreed = _isRequiredTermsAgreed && _isMarketingTermsAgreed;
  }

  Future<void> _handleComplete(Map<String, dynamic> signupData) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 개발 환경에서 SSL 인증서 검증 우회 (프로덕션에서는 제거 필요)
      HttpOverrides.global = _MyHttpOverrides();

      // 서버 IP 설정
      const String serverIp = '3.34.214.133';
      const String url = 'https://$serverIp/sign-up';

      // 이미지의 JSON 형식에 맞춰 요청 데이터 준비
      final Map<String, String> requestData = {
        'name': signupData['name'],
        'account_id': signupData['id'],
        'email': signupData['email'],
        'password': signupData['password'],
        'phone_number': signupData['phone'],
      };

      developer.log('POST $url');
      developer.log('Request: $requestData');

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
        // 응답이 단순 문자열인지 JSON인지 확인
        final responseBody = response.body.trim();

        // 단순 문자열 응답 처리
        if (responseBody == 'Sign-up successful') {
          // 성공: 회원가입 완료 페이지로 이동
          if (mounted) {
            Navigator.pushNamed(context, '/signup-success');
          }
          developer.log('Sign-up successful');
        } else if (responseBody == 'User ID already exists!') {
          // 중복된 아이디
          if (mounted) {
            _showErrorDialog(message: '이미 존재하는 아이디입니다.\n다른 아이디를 사용해주세요.');
          }
          developer.log('Sign-up failed: User ID already exists');
        } else {
          // JSON 응답 시도
          try {
            final responseData = json.decode(responseBody);
            if (responseData['success'] == true ||
                responseData['sign_up'] == 'successful') {
              // 성공: 회원가입 완료 페이지로 이동
              if (mounted) {
                Navigator.pushNamed(context, '/signup-success');
              }
              developer.log('Sign-up successful');
            } else {
              // 실패: 에러 팝업 표시
              final errorMessage =
                  responseData['error'] ??
                  responseData['message'] ??
                  '회원가입에 실패했습니다.';
              if (mounted) {
                _showErrorDialog(message: errorMessage);
              }
              developer.log('Sign-up failed: $responseData');
            }
          } catch (e) {
            // JSON 파싱 실패 - 서버 응답 그대로 표시
            developer.log('Non-JSON response: $responseBody');
            if (mounted) {
              _showErrorDialog(
                message: responseBody.isNotEmpty
                    ? responseBody
                    : '회원가입에 실패했습니다.',
              );
            }
          }
        }
      } else {
        // 서버 오류
        if (mounted) {
          _showErrorDialog();
        }
        developer.log('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog();
      }
      developer.log('Sign-up error: $e');
    }
  }

  void _showErrorDialog({String? message}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '오류',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          content: Text(
            message ?? '문제가 발생했습니다. 잠시 후 다시 시도해주세요',
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF666666),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '확인',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
          ],
        );
      },
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
