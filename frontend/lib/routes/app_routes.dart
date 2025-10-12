import 'package:flutter/material.dart';
import '../screens/auth/login_page.dart';
import '../screens/auth/signup_page.dart';
import '../screens/auth/signup_terms_page.dart';
import '../screens/auth/signup_success_page.dart';
import '../screens/auth/reset_password_page.dart';
import '../screens/auth/password_reset_form_page.dart';
import '../screens/auth/password_reset_success_page.dart';
import '../screens/account/find_id_page.dart';
import '../screens/account/find_id_error_page.dart';
import '../screens/account/find_id_verification_page.dart';
import '../screens/account/find_id_result_page.dart';
import '../screens/account/find_password_page.dart';
import '../screens/account/find_password_error_page.dart';
import '../screens/account/find_password_verification_page.dart';
import '../screens/account/find_password_reset_page.dart';
import '../screens/main_navigation_page.dart';
import '../screens/home_page.dart';
import '../screens/academy_list_page.dart';
import '../screens/academy_detail_page.dart';
import '../screens/workbook_page.dart';

class AppRoutes {
  static const String mainNavigation = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String signupTerms = '/signup-terms';
  static const String signupSuccess = '/signup-success';
  static const String home = '/home';
  static const String academy = '/academy';
  static const String academyDetail = '/academy/detail';
  static const String workbook = '/workbook';
  static const String findId = '/find-id';
  static const String findIdError = '/find-id-error';
  static const String findIdVerification = '/find-id-verification';
  static const String findIdResult = '/find-id-result';
  static const String findPassword = '/find-password';
  static const String findPasswordError = '/find-password-error';
  static const String findPasswordVerification = '/find-password-verification';
  static const String findPasswordReset = '/find-password-reset';
  static const String passwordResetForm = '/password-reset-form';
  static const String passwordResetSuccess = '/password-reset-success';
  static const String resetPassword = '/reset-password';

  static Map<String, WidgetBuilder> get routes => {
    mainNavigation: (context) => const MainNavigationPage(),
    login: (context) => const LoginPage(),
    signup: (context) => const SignUpPage(),
    signupTerms: (context) => const SignUpTermsPage(),
    signupSuccess: (context) => const SignUpSuccessPage(),
    home: (context) => const HomePage(),
    academy: (context) => const AcademyListPage(),
    workbook: (context) => const WorkbookPage(),
    findId: (context) => const FindIDPage(),
    findIdError: (context) => const FindIDErrorPage(),
    findPassword: (context) => const FindPasswordPage(),
    findPasswordError: (context) => const FindPasswordErrorPage(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case findIdVerification:
        return MaterialPageRoute(
          builder: (context) => const FindIDVerificationPage(),
          settings: settings,
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
          builder: (context) => const FindPasswordVerificationPage(),
          settings: settings,
        );
      case resetPassword:
        return MaterialPageRoute(
          builder: (context) => const ResetPasswordPage(),
          settings: settings,
        );
      case findPasswordReset:
        return MaterialPageRoute(
          builder: (context) => const FindPasswordResetPage(),
        );
      case passwordResetForm:
        return MaterialPageRoute(
          builder: (context) => const PasswordResetFormPage(),
          settings: settings,
        );
      case passwordResetSuccess:
        return MaterialPageRoute(
          builder: (context) => const PasswordResetSuccessPage(),
        );
      case academyDetail:
        final args = settings.arguments as AcademyData?;
        if (args == null) {
          return null;
        }
        return MaterialPageRoute(
          builder: (context) => AcademyDetailPage(academy: args),
        );
      default:
        return null;
    }
  }
}
