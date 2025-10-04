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
import '../screens/find_password_reset_page.dart';
import '../screens/password_reset_success_page.dart';
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
  static const String findPasswordReset = '/find-password-reset';
  static const String passwordResetSuccess = '/password-reset-success';
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
        return MaterialPageRoute(
          builder: (context) => const FindIDVerificationPage(),
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
        return MaterialPageRoute(
          builder: (context) =>
              const FindPasswordVerificationPage(userName: ''),
        );
      case findPasswordReset:
        return MaterialPageRoute(
          builder: (context) => const FindPasswordResetPage(),
        );
      case passwordResetSuccess:
        return MaterialPageRoute(
          builder: (context) => const PasswordResetSuccessPage(),
        );
      default:
        return null;
    }
  }
}
