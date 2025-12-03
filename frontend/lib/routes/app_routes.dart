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
import '../screens/academy/academy_page.dart';
import '../screens/academy/academy_list_page.dart';
import '../screens/academy/academy_detail_page.dart';
import '../screens/workbook/workbook_page.dart';
import '../screens/workbook/workbook_detail_page.dart';
import 'package:get_it/get_it.dart';
import '../config/app_dependencies.dart';
import '../screens/workbook/chapter_detail_page.dart';
import '../screens/workbook/question_detail_page.dart';
import '../application/explanation/question_explanation_controller.dart';

// QuestionStatus enum을 사용하기 위해 chapter_detail_page import
// (QuestionStatus는 chapter_detail_page.dart에 정의되어 있음)
import '../screens/mypage/mypage.dart';
import '../screens/mypage/display_settings_page.dart';
import '../screens/mypage/homework_status_page.dart';
import '../screens/mypage/learning_statistics_page.dart';
import '../screens/mypage/account_management_page.dart';
import '../screens/mypage/academy_management_page.dart';
import '../screens/mypage/notification_settings_page.dart';
import '../screens/notification/notification_page.dart';
import '../screens/upload/upload_images_page.dart';
import '../screens/grading_history/edit_grading_result_page.dart';
import '../screens/continuous_learning_detail_page.dart';
import '../screens/loading_page.dart';
import '../screens/problem_solution_temp_page.dart';
import '../domain/learning/get_monthly_learning_status_use_case.dart';

class AppRoutes {
  static const String mainNavigation = '/';
  static const String loading = '/loading';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String signupTerms = '/signup-terms';
  static const String signupSuccess = '/signup-success';
  static const String home = '/home';
  static const String academy = '/academy';
  static const String academyList = '/academy/list';
  static const String academyDetail = '/academy/detail';
  static const String workbook = '/workbook';
  static const String workbookDetail = '/workbook/detail';
  static const String chapterDetail = '/workbook/chapter-detail';
  static const String questionDetail = '/workbook/question-detail';
  static const String mypage = '/mypage';
  static const String displaySettings = '/mypage/display-settings';
  static const String homeworkStatus = '/mypage/homework-status';
  static const String learningStatistics = '/mypage/learning-statistics';
  static const String accountManagement = '/mypage/account-management';
  static const String academyManagement = '/mypage/academy-management';
  static const String notificationSettings = '/mypage/notification-settings';
  static const String notification = '/notification';
  static const String continuousLearningDetail = '/continuous-learning-detail';
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
  static const String uploadImages = '/upload/images';
  static const String editGradingResult = '/upload/edit-result';
  static const String problemTemp = '/problem-temp';

  static Map<String, WidgetBuilder> get routes => {
    mainNavigation: (context) => const MainNavigationPage(),
    loading: (context) => const LoadingPage(),
    login: (context) => const LoginPage(),
    signup: (context) => const SignUpPage(),
    signupTerms: (context) => const SignUpTermsPage(),
    signupSuccess: (context) => const SignUpSuccessPage(),
    home: (context) => const HomePage(),
    academy: (context) => const AcademyPage(),
    academyList: (context) => const AcademyListPage(),
    workbook: (context) => const WorkbookPage(),
    mypage: (context) => const MyPage(),
    displaySettings: (context) => const DisplaySettingsPage(),
    homeworkStatus: (context) => const HomeworkStatusPage(),
    learningStatistics: (context) => const LearningStatisticsPage(),
    accountManagement: (context) => const AccountManagementPage(),
    academyManagement: (context) => const AcademyManagementPage(),
    notificationSettings: (context) => const NotificationSettingsPage(),
    notification: (context) => const NotificationPage(),
    findId: (context) => const FindIDPage(),
    findIdError: (context) => const FindIDErrorPage(),
    findPassword: (context) => const FindPasswordPage(),
    findPasswordError: (context) => const FindPasswordErrorPage(),
    uploadImages: (context) => const UploadImagesPage(),
    problemTemp: (context) => const ProblemSolutionTempPage(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final getIt = GetIt.instance;
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
      case workbookDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return null;
        }

        final bookId = args['bookId'] as int?;
        final academyUserId = args['academyUserId'] as int?;

        if (bookId == null || academyUserId == null) {
          // 필수 파라미터가 없으면 에러 처리
          return MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(child: Text('문제집 정보가 올바르지 않습니다.')),
            ),
          );
        }

        return MaterialPageRoute(
          builder: (context) => WorkbookDetailPage(
            workbookName: args['workbookName'] as String,
            thumbnailPath: args['thumbnailPath'] as String?,
            bookId: bookId,
            academyUserId: academyUserId,
            getChaptersUseCase:
                AppDependencies.getChaptersForBookUseCase,
          ),
        );
      case chapterDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return null;
        }

        final chapterId = args['chapterId'] as int?;
        final academyUserId = args['academyUserId'] as int?;

        if (chapterId == null || academyUserId == null) {
          return MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(child: Text('챕터 정보가 올바르지 않습니다.')),
            ),
          );
        }

        return MaterialPageRoute(
          builder: (context) => ChapterDetailPage(
            chapterId: chapterId,
            academyUserId: academyUserId,
            workbookName: args['workbookName'] as String,
            chapterName: args['chapterName'] as String,
            getChapterQuestionStatusesUseCase:
                AppDependencies.getChapterQuestionStatusesUseCase,
          ),
        );
      case questionDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(child: Text('문제 정보가 올바르지 않습니다.')),
            ),
          );
        }

        final chapterId = args['chapterId'] as int?;
        final academyUserId = args['academyUserId'] as int?;
        final workbookName = args['workbookName'] as String?;
        final chapterName = args['chapterName'] as String?;
        final questionNumber = args['questionNumber'] as int?;
        final status = args['status'] as QuestionStatus?;
        final studentResponseId = args['studentResponseId'] as int?;

        if (chapterId == null ||
            academyUserId == null ||
            workbookName == null ||
            chapterName == null ||
            questionNumber == null ||
            status == null) {
          return MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(child: Text('문제 정보가 올바르지 않습니다.')),
            ),
          );
        }

        final explanationController = getIt<QuestionExplanationController>();

        return MaterialPageRoute(
          builder: (context) => QuestionDetailPage(
            chapterId: chapterId,
            academyUserId: academyUserId,
            workbookName: workbookName,
            chapterName: chapterName,
            questionNumber: questionNumber,
            status: status,
            initialStudentResponseId: studentResponseId,
            explanationController: explanationController,
          ),
        );
      case editGradingResult:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null ||
            args['studentResponseId'] == null ||
            args['academyUserId'] == null) {
          // studentResponseId 또는 academyUserId가 없으면 에러 처리
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Center(
                child: Text(
                  args == null || args['studentResponseId'] == null
                      ? '학생 응답 ID가 필요합니다.'
                      : '학원 사용자 ID가 필요합니다.',
                ),
              ),
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (context) => EditGradingResultPage(
            studentResponseId: args['studentResponseId'] as int,
            academyUserId: args['academyUserId'] as int,
            getStudentAnswersUseCase:
                AppDependencies.getStudentAnswersForResponseUseCase,
            updateStudentAnswersUseCase:
                AppDependencies.updateStudentAnswersUseCase,
            getSectionImageUseCase:
                AppDependencies.getSectionImageUseCase,
            updateSingleStudentAnswerUseCase:
                AppDependencies.updateSingleStudentAnswerUseCase,
          ),
          settings: settings,
        );
      case continuousLearningDetail:
        return MaterialPageRoute(
          builder: (context) => ContinuousLearningDetailPage(
            monthlyStatusUseCase:
                getIt<GetMonthlyLearningStatusUseCase>(),
          ),
          settings: settings,
        );
      default:
        return null;
    }
  }
}
