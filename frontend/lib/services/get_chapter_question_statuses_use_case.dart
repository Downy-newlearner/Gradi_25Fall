import '../domain/chapter/chapter_repository.dart';
import '../domain/student_answer/student_answer_repository.dart';
import '../domain/student_answer/student_answer_query.dart';
import 'models/question_status_model.dart';
import 'policies/answer_selection_policy.dart';

/// 챕터의 문제별 풀이 상태 조회 UseCase (Application Layer)
///
/// **책임**:
/// - Domain Entity들을 조합하여 UI에 필요한 데이터 생성
/// - 상태 계산 로직 포함
/// - 정책 로직은 별도 객체로 분리
class GetChapterQuestionStatusesUseCase {
  final ChapterRepository _chapterRepository;
  final StudentAnswerRepository _studentAnswerRepository;
  final AnswerSelectionPolicy _selectionPolicy;

  GetChapterQuestionStatusesUseCase({
    required ChapterRepository chapterRepository,
    required StudentAnswerRepository studentAnswerRepository,
    AnswerSelectionPolicy? selectionPolicy,
  })  : _chapterRepository = chapterRepository,
        _studentAnswerRepository = studentAnswerRepository,
        _selectionPolicy = selectionPolicy ?? AnswerSelectionPolicy();

  /// 챕터의 문제별 풀이 상태 반환
  ///
  /// 반환값: 문제 번호 순서대로 정렬된 상태 리스트
  Future<List<QuestionStatusModel>> call({
    required int chapterId,
    required int academyUserId,
  }) async {
    // 1. 챕터 정보 조회
    final chapter = await _chapterRepository.getChapterById(chapterId);

    // 2. 학생 답안 조회 (Query 객체 사용)
    final answers = await _studentAnswerRepository.getStudentAnswers(
      StudentAnswerQuery.byChapter(
        chapterId: chapterId,
        academyUserId: academyUserId,
      ),
    );

    // 3. question_number별로 Map 생성 (정책 적용)
    final answerMap = <int, bool?>{};
    for (final answer in answers) {
      final existing = answerMap[answer.questionNumber];
      answerMap[answer.questionNumber] = _selectionPolicy.selectAnswer(
        existing,
        answer.isCorrect,
      );
    }

    // 4. 전체 문제 번호 리스트 생성 (1부터 totalChapterQuestion까지)
    final result = <QuestionStatusModel>[];
    for (int questionNumber = 1;
        questionNumber <= chapter.totalChapterQuestion;
        questionNumber++) {
      result.add(QuestionStatusModel(
        questionNumber: questionNumber,
        isCorrect: answerMap[questionNumber], // null일 수 있음
      ));
    }

    return result;
  }
}

