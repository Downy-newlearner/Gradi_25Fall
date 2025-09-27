import 'package:flutter/material.dart';
import '../screens/login_page.dart';
import '../screens/signup_page.dart';
import '../screens/find_id_page.dart';
import '../screens/find_id_error_page.dart';
import '../screens/find_id_verification_page.dart';
import '../screens/find_id_result_page.dart';
import '../screens/find_password_page.dart';
import '../screens/find_password_error_page.dart';
import '../screens/find_password_verification_page.dart';
import '../screens/reset_password_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String findId = '/find-id';
  static const String findIdError = '/find-id-error';
  static const String findIdVerification = '/find-id-verification';
  static const String findIdResult = '/find-id-result';
  static const String findPassword = '/find-password';
  static const String findPasswordError = '/find-password-error';
  static const String findPasswordVerification = '/find-password-verification';
  static const String resetPassword = '/reset-password';

  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginPage(),
    signup: (context) => const SignUpPage(),
    findId: (context) => const FindIDPage(),
    findIdError: (context) => const FindIDErrorPage(),
    findPassword: (context) => const FindPasswordPage(),
    findPasswordError: (context) => const FindPasswordErrorPage(),
    resetPassword: (context) => const ResetPasswordPage(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case findIdVerification:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) =>
              FindIDVerificationPage(userName: args?['userName'] ?? ''),
        );
      case findIdResult:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => FindIDResultPage(
            userName: args?['userName'] ?? '',
            userId: args?['userId'] ?? '',
          ),
        );
      case findPasswordVerification:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) =>
              FindPasswordVerificationPage(userName: args?['userName'] ?? ''),
        );
      default:
        return null;
    }
  }
}
