import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화 (이미 초기화되어 있으면 스킵)
  try {
    // 이미 초기화되어 있는지 확인
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase 초기화 성공');
    } else {
      debugPrint('ℹ️ Firebase는 이미 초기화되어 있습니다.');
    }
  } catch (e) {
    debugPrint('❌ Firebase 초기화 실패: $e');
    // 중복 초기화 오류는 무시 (Hot Reload/Restart 시 발생 가능)
    if (e.toString().contains('duplicate-app')) {
      debugPrint('ℹ️ Firebase가 이미 초기화되어 있습니다. (Hot Reload/Restart)');
    } else {
      // iOS에서 GoogleService-Info.plist를 찾지 못하는 경우
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint(
          '⚠️ iOS: GoogleService-Info.plist 파일이 Xcode 프로젝트에 포함되어 있는지 확인하세요.',
        );
        debugPrint('   파일 경로: ios/Runner/GoogleService-Info.plist');
        debugPrint('   Xcode에서: Runner.xcworkspace를 열고 파일이 프로젝트에 추가되어 있는지 확인');
      }
      rethrow;
    }
  }

  // FCM 초기화
  try {
    await FCMService().initialize();
  } catch (e) {
    debugPrint('❌ FCM 초기화 실패: $e');
    // FCM 초기화 실패해도 앱은 계속 실행
  }

  // 세로 방향 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const GradiApp());
}

class GradiApp extends StatelessWidget {
  const GradiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'GRADI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Routing configuration
      initialRoute: '/', // MainNavigationPage로 시작
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,

      // Handle unknown routes
      onUnknownRoute: (settings) =>
          MaterialPageRoute(builder: (context) => const _UnknownRoutePage()),
    );
  }
}

class _UnknownRoutePage extends StatelessWidget {
  const _UnknownRoutePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('페이지를 찾을 수 없습니다')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            SizedBox(height: 16),
            Text(
              '요청하신 페이지를 찾을 수 없습니다.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'URL을 확인하고 다시 시도해주세요.',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
