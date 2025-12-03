import 'package:get_it/get_it.dart';

import '../domain/chapter/get_chapters_for_book_use_case.dart';
import '../services/get_chapter_question_statuses_use_case.dart';
import '../domain/student_answer/student_answer_repository.dart';
import '../domain/student_answer/get_student_answers_for_response_use_case.dart';
import '../domain/student_answer/update_student_answers_use_case.dart';
import '../domain/student_answer/update_single_student_answer_use_case.dart';
import '../domain/section_image/get_section_image_use_case.dart';

final GetIt _getIt = GetIt.instance;

/// AppDependencies는 과거 static 싱글톤을 사용하던 코드를 위한
/// **임시 래퍼**입니다.
///
/// 새 코드는 `getIt<>()`을 직접 사용하는 것을 권장하며,
/// 이 클래스는 점진적으로 제거될 예정입니다.
@Deprecated('Use getIt<>() from di_container.dart directly instead.')
class AppDependencies {
  // Chapter
  static GetChaptersForBookUseCase get getChaptersForBookUseCase =>
      _getIt<GetChaptersForBookUseCase>();

  static GetChapterQuestionStatusesUseCase
      get getChapterQuestionStatusesUseCase =>
          _getIt<GetChapterQuestionStatusesUseCase>();

  // Student Answer
  static StudentAnswerRepository get studentAnswerRepository =>
      _getIt<StudentAnswerRepository>();

  static GetStudentAnswersForResponseUseCase
      get getStudentAnswersForResponseUseCase =>
          _getIt<GetStudentAnswersForResponseUseCase>();

  static UpdateStudentAnswersUseCase get updateStudentAnswersUseCase =>
      _getIt<UpdateStudentAnswersUseCase>();

  static UpdateSingleStudentAnswerUseCase
      get updateSingleStudentAnswerUseCase =>
          _getIt<UpdateSingleStudentAnswerUseCase>();

  // Section Image
  static GetSectionImageUseCase get getSectionImageUseCase =>
      _getIt<GetSectionImageUseCase>();
}
