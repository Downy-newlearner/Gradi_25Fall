import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'dart:developer' as developer;

/// 앱 시작 시 로딩 페이지
///
/// 동작 방식:
/// 1. 자동 로그인이 선택된 경우 (토큰이 있는 경우):
///    - 로딩 페이지를 표시하면서 필요한 API 호출
///    - 완료 후 메인 네비게이션 페이지로 이동
/// 2. 로그인되지 않은 경우:
///    - 로그인 페이지로 이동
class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// 앱 초기화 로직
  Future<void> _initializeApp() async {
    try {
      final authService = AuthService();

      // 자동 로그인 설정 확인
      final isAutoLoginEnabled = await authService.isAutoLoginEnabled();

      if (!mounted) return;

      if (!isAutoLoginEnabled) {
        // 자동 로그인 비활성화 → 로그인 페이지로 이동
        developer.log('ℹ️ 자동 로그인 비활성화 - 로그인 페이지로 이동');
        // 자동 로그인이 비활성화된 경우 토큰이 남아있을 수 있으므로 삭제
        await authService.clearTokens(clearAutoLogin: false);
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
        return;
      }

      // 자동 로그인 활성화 → Access Token 확인
      final accessToken = await authService.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        // 토큰 없음 → 로그인 페이지로 이동
        developer.log('ℹ️ 토큰 없음 - 로그인 페이지로 이동');
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
        return;
      }

      // 토큰 만료 확인 및 갱신
      final isExpired = authService.isTokenExpired(accessToken);

      if (isExpired) {
        developer.log('⚠️ Access Token 만료됨 - Refresh Token으로 갱신 시도...');
        final refreshed = await authService.refreshAccessToken();

        if (!refreshed) {
          // Refresh Token도 만료되었거나 갱신 실패 → 로그인 페이지로 이동
          developer.log('❌ 토큰 갱신 실패 - 로그인 페이지로 이동');
          await authService.clearTokens();
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          }
          return;
        }

        developer.log('✅ Access Token 갱신 성공');
      } else {
        developer.log('✅ Access Token 유효함');
      }

      // 자동 로그인: 필요한 API 호출
      developer.log('🔄 자동 로그인 감지 - 사용자 정보 초기화 중...');

      try {
        // 사용자 정보 초기화 (API 호출)
        // fetchUserFromServer 내부에서 토큰 만료 시 자동 갱신 처리됨
        await UserService().initialize();
        developer.log('✅ 사용자 정보 초기화 완료');
      } catch (e) {
        developer.log('❌ 사용자 정보 초기화 실패: $e');
        // 초기화 실패해도 메인 페이지로 이동 (캐시된 데이터 사용)
      }

      // 메인 네비게이션 페이지로 이동
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      developer.log('❌ 앱 초기화 중 오류 발생: $e');
      // 오류 발생 시 로그인 페이지로 이동
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 상태바 스타일 설정 (흰색 아이콘)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // Figma: linear-gradient(153deg, rgba(172, 91, 248, 1) 9%, rgba(99, 106, 207, 1) 92%)
            colors: [
              Color(0xFFAC5BF8), // rgba(172, 91, 248, 1)
              Color(0xFF636ACF), // rgba(99, 106, 207, 1)
            ],
            stops: [0.09, 0.92], // 9%, 92%
            transform: GradientRotation(2.67), // 153 degrees in radians
          ),
        ),
        child: Center(
          child: Text(
            'GRADI',
            style: TextStyle(
              fontFamily: 'AppleSDGothicNeoH00',
              fontWeight: FontWeight.w400,
              fontSize: 110.648,
              height: 1.491, // line-height: 165px / 110.648px
              letterSpacing: -0.06, // -6%
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
