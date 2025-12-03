import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/user_service.dart';
import '../services/academy_service.dart';
import '../data/notification/notification_local_data_source.dart';
import '../services/assessment_local_store.dart';
import '../domain/notification/notification_repository.dart';
import '../data/notification/notification_repository_impl.dart';
import '../services/fcm_service.dart';
import '../services/upload_sse_service.dart';
import '../services/grading_history_api.dart';
import '../services/workbook_api.dart';
import '../services/assessment_api.dart';
import '../services/continuous_learning_api.dart';
import '../services/student_answer_api.dart';
import '../services/section_image_api.dart';
import '../data/chapter/chapter_api.dart';
import '../data/mappers/grading_history_mapper.dart';
import '../data/mappers/workbook_mapper.dart';
import '../services/student_answer_mapper.dart';
import '../services/section_image_mapper.dart';
import '../domain/grading_history/grading_history_repository.dart';
import '../domain/workbook/workbook_repository.dart';
import '../domain/student_answer/student_answer_repository.dart';
import '../domain/section_image/section_image_repository.dart';
import '../domain/chapter/chapter_repository.dart';
import '../services/assessment_repository.dart';
import '../services/grading_history_repository_impl.dart';
import '../services/workbook_repository_impl.dart';
import '../services/student_answer_repository_impl.dart';
import '../services/section_image_repository_impl.dart';
import '../services/explanation_repository_impl.dart';
import '../data/chapter/chapter_repository_impl.dart';
import '../domain/chapter/get_chapters_for_book_use_case.dart';
import '../services/get_chapter_question_statuses_use_case.dart';
import '../domain/student_answer/get_student_answers_for_response_use_case.dart';
import '../domain/student_answer/update_student_answers_use_case.dart';
import '../domain/student_answer/update_single_student_answer_use_case.dart';
import '../domain/section_image/get_section_image_use_case.dart';
import '../services/get_monthly_learning_status_use_case_impl.dart';
import '../domain/learning/get_monthly_learning_status_use_case.dart';
import '../services/learning_completion_service_impl.dart';
import '../services/policies/answer_selection_policy.dart';
import '../services/explanation_api.dart';
import '../data/explanation/explanation_mapper.dart';
import '../domain/explanation/explanation_repository.dart';
import '../domain/explanation/get_explanation_use_case.dart';
import '../domain/explanation/request_explanation_use_case.dart';
import '../application/explanation/explanation_service.dart';
import '../application/explanation/question_explanation_controller.dart';
import '../services/daily_learning_service.dart';

/// 전역 DI Container 인스턴스
final getIt = GetIt.instance;

/// Core 의존성 등록 (외부 라이브러리 등)
void registerCore() {
  getIt.registerLazySingleton<http.Client>(() => http.Client());
}

/// Infrastructure Services 등록
void registerInfrastructureServices() {
  // Auth & User & Academy & Location
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<LocationService>(() => LocationService());
  getIt.registerLazySingleton<UserService>(
    () => UserService(authService: getIt<AuthService>()),
  );
  getIt.registerLazySingleton<AcademyService>(
    () => AcademyService(authService: getIt<AuthService>()),
  );

  // Notification Repository
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      getIt<NotificationLocalDataSource>(),
    ),
  );

  // FCM Service (상태 없는 singleton)
  getIt.registerLazySingleton<FCMService>(
    () => FCMService(
      notificationRepository: getIt<NotificationRepository>(),
    ),
  );

  // Upload SSE Service (연결 상태를 가지므로 factory)
  getIt.registerFactory<UploadSseService>(
    () => UploadSseService(
      authService: getIt<AuthService>(),
    ),
  );

  // Daily Learning Service
  getIt.registerLazySingleton<DailyLearningService>(
    () => DailyLearningService(
      workbookApi: getIt<WorkbookApi>(),
      academyService: getIt<AcademyService>(),
      authService: getIt<AuthService>(),
    ),
  );
}

/// Data Sources 등록
void registerDataSources({required SharedPreferences sharedPrefs}) {
  // SharedPreferences를 singleton으로 등록
  getIt.registerSingleton<SharedPreferences>(sharedPrefs);

  // Local stores / data sources
  getIt.registerLazySingleton<AssessmentLocalStore>(() => AssessmentLocalStore());

  getIt.registerLazySingleton<NotificationLocalDataSource>(
    () => NotificationLocalDataSource(getIt<SharedPreferences>()),
  );
}

/// Mapper 등록
void registerMappers() {
  getIt.registerLazySingleton<GradingHistoryMapper>(() => GradingHistoryMapper());
  getIt.registerLazySingleton<WorkbookMapper>(() => WorkbookMapper());
  getIt.registerLazySingleton<StudentAnswerMapper>(() => StudentAnswerMapper());
  getIt.registerLazySingleton<SectionImageMapper>(() => SectionImageMapper());
  getIt.registerLazySingleton<ExplanationMapper>(() => ExplanationMapper());
}

/// API 등록
void registerApis() {
  getIt.registerLazySingleton<GradingHistoryApi>(
    () => GradingHistoryApi(
      authService: getIt<AuthService>(),
      httpClient: getIt<http.Client>(),
    ),
  );

  getIt.registerLazySingleton<WorkbookApi>(
    () => WorkbookApi(
      authService: getIt<AuthService>(),
      httpClient: getIt<http.Client>(),
    ),
  );

  getIt.registerLazySingleton<AssessmentApi>(
    () => AssessmentApi(
      authService: getIt<AuthService>(),
      httpClient: getIt<http.Client>(),
    ),
  );

  getIt.registerLazySingleton<ContinuousLearningApi>(
    () => ContinuousLearningApi(
      authService: getIt<AuthService>(),
      httpClient: getIt<http.Client>(),
    ),
  );

  getIt.registerLazySingleton<StudentAnswerApi>(
    () => StudentAnswerApi(
      authService: getIt<AuthService>(),
      httpClient: getIt<http.Client>(),
    ),
  );

  getIt.registerLazySingleton<SectionImageApi>(
    () => SectionImageApi(
      authService: getIt<AuthService>(),
      httpClient: getIt<http.Client>(),
    ),
  );

  getIt.registerLazySingleton<ChapterApi>(
    () => ChapterApi(
      authService: getIt<AuthService>(),
      httpClient: getIt<http.Client>(),
    ),
  );

  getIt.registerLazySingleton<ExplanationApi>(
    () => ExplanationApi(
      tokenProvider: () => getIt<AuthService>().ensureValidAccessToken(),
      httpClient: getIt<http.Client>(),
    ),
  );
}

/// Repository 등록
void registerRepositories() {
  // Impl 등록
  getIt.registerLazySingleton<AssessmentRepository>(
    () => AssessmentRepository(
      api: getIt<AssessmentApi>(),
      localStore: getIt<AssessmentLocalStore>(),
      academyService: getIt<AcademyService>(),
    ),
  );

  getIt.registerLazySingleton<GradingHistoryRepositoryImpl>(
    () => GradingHistoryRepositoryImpl(
      api: getIt<GradingHistoryApi>(),
      mapper: getIt<GradingHistoryMapper>(),
      academyService: getIt<AcademyService>(),
    ),
  );

  getIt.registerLazySingleton<WorkbookRepositoryImpl>(
    () => WorkbookRepositoryImpl(
      api: getIt<WorkbookApi>(),
      mapper: getIt<WorkbookMapper>(),
      academyService: getIt<AcademyService>(),
    ),
  );

  getIt.registerLazySingleton<StudentAnswerRepositoryImpl>(
    () => StudentAnswerRepositoryImpl(
      api: getIt<StudentAnswerApi>(),
      mapper: getIt<StudentAnswerMapper>(),
    ),
  );

  getIt.registerLazySingleton<SectionImageRepositoryImpl>(
    () => SectionImageRepositoryImpl(
      api: getIt<SectionImageApi>(),
      mapper: getIt<SectionImageMapper>(),
    ),
  );

  getIt.registerLazySingleton<ChapterRepositoryImpl>(
    () => ChapterRepositoryImpl(
      api: getIt<ChapterApi>(),
    ),
  );

  getIt.registerLazySingleton<ExplanationRepositoryImpl>(
    () => ExplanationRepositoryImpl(
      api: getIt<ExplanationApi>(),
      mapper: getIt<ExplanationMapper>(),
    ),
  );

  // Interface 타입으로도 등록
  getIt.registerLazySingleton<GradingHistoryRepository>(
    () => getIt<GradingHistoryRepositoryImpl>(),
  );
  getIt.registerLazySingleton<WorkbookRepository>(
    () => getIt<WorkbookRepositoryImpl>(),
  );
  getIt.registerLazySingleton<StudentAnswerRepository>(
    () => getIt<StudentAnswerRepositoryImpl>(),
  );
  getIt.registerLazySingleton<SectionImageRepository>(
    () => getIt<SectionImageRepositoryImpl>(),
  );
  getIt.registerLazySingleton<ChapterRepository>(
    () => getIt<ChapterRepositoryImpl>(),
  );
  getIt.registerLazySingleton<ExplanationRepository>(
    () => getIt<ExplanationRepositoryImpl>(),
  );
}

/// UseCase 등록
void registerUseCases() {
  // Chapter
  getIt.registerLazySingleton<GetChaptersForBookUseCase>(
    () => GetChaptersForBookUseCase(
      repository: getIt<ChapterRepository>(),
    ),
  );

  getIt.registerLazySingleton<GetChapterQuestionStatusesUseCase>(
    () => GetChapterQuestionStatusesUseCase(
      chapterRepository: getIt<ChapterRepository>(),
      studentAnswerRepository: getIt<StudentAnswerRepository>(),
      selectionPolicy: AnswerSelectionPolicy(),
    ),
  );

  // Student Answer
  getIt.registerLazySingleton<GetStudentAnswersForResponseUseCase>(
    () => GetStudentAnswersForResponseUseCase(
      repository: getIt<StudentAnswerRepository>(),
    ),
  );

  getIt.registerLazySingleton<UpdateStudentAnswersUseCase>(
    () => UpdateStudentAnswersUseCase(
      repository: getIt<StudentAnswerRepository>(),
    ),
  );

  getIt.registerLazySingleton<UpdateSingleStudentAnswerUseCase>(
    () => UpdateSingleStudentAnswerUseCase(
      api: getIt<StudentAnswerApi>(),
    ),
  );

  // Section Image
  getIt.registerLazySingleton<GetSectionImageUseCase>(
    () => GetSectionImageUseCase(
      repository: getIt<SectionImageRepository>(),
    ),
  );

  // Monthly Learning Status
  getIt.registerLazySingleton<GetMonthlyLearningStatusUseCase>(
    () => GetMonthlyLearningStatusUseCaseImpl(
      assessmentRepository: getIt<AssessmentRepository>(),
      gradingHistoryRepository: getIt<GradingHistoryRepository>(),
      completionService: const LearningCompletionServiceImpl(),
    ),
  );

  // Explanation
  getIt.registerLazySingleton<GetExplanationUseCase>(
    () => GetExplanationUseCase(
      repository: getIt<ExplanationRepository>(),
    ),
  );

  getIt.registerLazySingleton<RequestExplanationUseCase>(
    () => RequestExplanationUseCase(
      repository: getIt<ExplanationRepository>(),
    ),
  );

  getIt.registerLazySingleton<ExplanationService>(
    () => ExplanationService(
      repository: getIt<ExplanationRepository>(),
      getExplanationUseCase: getIt<GetExplanationUseCase>(),
      requestExplanationUseCase: getIt<RequestExplanationUseCase>(),
      authService: getIt<AuthService>(),
      academyService: getIt<AcademyService>(),
    ),
  );

  getIt.registerFactory<QuestionExplanationController>(
    () => QuestionExplanationController(
      service: getIt<ExplanationService>(),
    ),
  );
}

/// DI Container 초기화
///
/// SharedPreferences는 main.dart에서 한 번만 생성해 주입합니다.
Future<void> setupDependencies({required SharedPreferences sharedPrefs}) async {
  registerCore();
  registerInfrastructureServices();
  registerDataSources(sharedPrefs: sharedPrefs);
  registerMappers();
  registerApis();
  registerRepositories();
  registerUseCases();
}


