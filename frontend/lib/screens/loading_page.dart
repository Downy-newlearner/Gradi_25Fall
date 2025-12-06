import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/assessment_repository.dart';
import '../services/academy_service.dart';
import '../services/fcm_service.dart';
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
  final getIt = GetIt.instance;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// 앱 초기화 로직
  Future<void> _initializeApp() async {
    try {
      final authService = getIt<AuthService>();
      final assessmentRepository = getIt<AssessmentRepository>();

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
        await getIt<UserService>().initialize();
        developer.log('✅ 사용자 정보 초기화 완료');
      } catch (e) {
        developer.log('❌ 사용자 정보 초기화 실패: $e');
        // 초기화 실패해도 메인 페이지로 이동 (캐시된 데이터 사용)
      }

      // 학원 목록 API 호출 및 디폴트 학원 선택
      try {
        final userId = await authService.getUserId();
        if (userId != null) {
          developer.log('🔄 학원 목록 조회 중...');
          final academyService = getIt<AcademyService>();
          final academies = await academyService.getUserAcademies(userId);

          // SharedPreferences에 학원 목록 저장
          await academyService.saveAcademiesToCache(academies);
          developer.log('✅ 학원 목록 캐시 저장 완료 (${academies.length}개)');

          // 디폴트 학원 선택 및 저장
          final defaultAcademyCode = await academyService
              .selectDefaultAcademyAsync(academies);
          if (defaultAcademyCode != null) {
            await academyService.saveDefaultAcademyCode(defaultAcademyCode);
            developer.log('✅ 디폴트 학원 선택 및 저장 완료 (Code: $defaultAcademyCode)');

            // 현재 달과 다음 달의 Assessment 데이터 로드 (디폴트 학원 사용)
            try {
              final now = DateTime.now();

              // 현재 달의 첫 번째 날 (UTC)
              final currentMonthStart = DateTime.utc(now.year, now.month, 1);

              // 다음 달 계산 (set 함수 사용)
              final nextMonthStart = _getNextMonth(currentMonthStart);

              // 현재 달과 다음 달 데이터를 병렬로 가져오기
              await Future.wait([
                assessmentRepository.getForMonth(
                  academyId: defaultAcademyCode,
                  dateTime: currentMonthStart,
                ),
                assessmentRepository.getForMonth(
                  academyId: defaultAcademyCode,
                  dateTime: nextMonthStart,
                ),
              ]);

              developer.log('✅ 현재 달과 다음 달 Assessment 데이터 로드 완료');
            } catch (e) {
              developer.log('⚠️ Assessment 데이터 로드 실패: $e');
              // 실패해도 앱은 계속 진행
            }
          } else {
            developer.log('⚠️ 디폴트 학원을 선택할 수 없음 (등록완료된 학원이 없음)');
          }
        } else {
          developer.log('⚠️ 사용자 ID를 가져올 수 없어 학원 목록 조회를 건너뜀');
        }
      } catch (e) {
        developer.log('⚠️ 학원 목록 조회 실패: $e');
        // 실패해도 앱은 계속 진행 (캐시된 데이터 사용 가능)
      }

      // FCM 토큰을 백엔드와 동기화
      try {
        final fcmService = getIt<FCMService>();
        await fcmService.syncTokenWithServer();
        developer.log('✅ FCM 토큰 동기화 완료');
      } catch (e) {
        developer.log('⚠️ FCM 토큰 동기화 실패: $e');
        // 실패해도 앱은 계속 진행
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

  /// 다음 달 계산 헬퍼 함수
  DateTime _getNextMonth(DateTime dateTime) {
    if (dateTime.month == 12) {
      return DateTime.utc(dateTime.year + 1, 1, 1);
    } else {
      return DateTime.utc(dateTime.year, dateTime.month + 1, 1);
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
