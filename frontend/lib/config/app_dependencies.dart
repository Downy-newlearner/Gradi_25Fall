import '../domain/chapter/chapter_repository.dart';
import '../domain/chapter/get_chapters_for_book_use_case.dart';
import '../data/chapter/chapter_repository_impl.dart';
import '../domain/student_answer/student_answer_repository.dart';
import '../domain/student_answer/get_student_answers_for_response_use_case.dart';
import '../domain/student_answer/update_student_answers_use_case.dart';
import '../services/student_answer_repository_impl.dart';
import '../domain/section_image/section_image_repository.dart';
import '../domain/section_image/get_section_image_use_case.dart';
import '../services/section_image_repository_impl.dart';
import '../services/get_chapter_question_statuses_use_case.dart';

/// 앱 전역 의존성 팩토리
///
/// UseCase, Repository 등의 인스턴스를 중앙에서 관리합니다.
///
/// **NOTE**:
/// - 지금은 static 싱글톤으로 사용하지만,
/// - 나중에 테스트/멀티 인스턴스가 필요하면
///   Stateful DI(Container, GetIt 등)로 갈아탈 예정.
///
/// 이 구조는 "composition root" 역할을 하며,
/// 나중에 DI 프레임워크로 교체하기 쉽도록 설계되었습니다.
class AppDependencies {
  // Chapter 관련 의존성
  static final ChapterRepository _chapterRepository = ChapterRepositoryImpl();

  static final GetChaptersForBookUseCase getChaptersForBookUseCase =
      GetChaptersForBookUseCase(repository: _chapterRepository);

  // Chapter Question Status 관련 의존성 (Application Layer)
  static final GetChapterQuestionStatusesUseCase
      getChapterQuestionStatusesUseCase = GetChapterQuestionStatusesUseCase(
    chapterRepository: _chapterRepository,
    studentAnswerRepository: _studentAnswerRepository,
  );

  // Student Answer 관련 의존성
  static final StudentAnswerRepository _studentAnswerRepository =
      StudentAnswerRepositoryImpl();

  // Repository 접근 (외부에서 직접 접근 필요 시)
  static StudentAnswerRepository get studentAnswerRepository =>
      _studentAnswerRepository;

  static final GetStudentAnswersForResponseUseCase
      getStudentAnswersForResponseUseCase =
      GetStudentAnswersForResponseUseCase(
        repository: _studentAnswerRepository,
      );

  static final UpdateStudentAnswersUseCase updateStudentAnswersUseCase =
      UpdateStudentAnswersUseCase(
        repository: _studentAnswerRepository,
      );

  // Section Image 관련 의존성
  static final SectionImageRepository _sectionImageRepository =
      SectionImageRepositoryImpl();

  static final GetSectionImageUseCase getSectionImageUseCase =
      GetSectionImageUseCase(
        repository: _sectionImageRepository,
      );
}
