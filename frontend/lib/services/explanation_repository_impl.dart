import '../domain/explanation/explanation_entity.dart';
import '../domain/explanation/explanation_repository.dart';
import '../domain/explanation/explanation_source.dart';
import '../data/explanation/explanation_mapper.dart';
import 'explanation_api.dart';

/// Explanation 도메인 Repository 구현체
class ExplanationRepositoryImpl implements ExplanationRepository {
  final ExplanationApi _api;
  final ExplanationMapper _mapper;

  ExplanationRepositoryImpl({
    required ExplanationApi api,
    required ExplanationMapper mapper,
  })  : _api = api,
        _mapper = mapper;

  @override
  Future<StudentAnswerInfo> findStudentAnswer(ExplanationSource source) async {
    final json = await _api.findStudentAnswer(
      studentResponseId: source.studentResponseId,
      questionNumber: source.question.questionNumber,
      subQuestionNumber: source.question.subQuestionNumber,
    );

    return StudentAnswerInfo(
      studentAnswerId: json['studentAnswerId'] as int,
      studentResponseId: json['studentResponseId'] as int,
      chapterId: json['chapterId'] as int,
      page: json['page'] as int,
      questionNumber: json['questionNumber'] as int,
      subQuestionNumber: json['subQuestionNumber'] as int,
      answer: json['answer'] as String,
      sectionUrl: json['section_url'] as String?,
      score: (json['score'] as num).toDouble(),
      correct: json['correct'] as bool,
    );
  }

  @override
  Future<ExplanationEntity?> getExplanation(ExplanationSource source) async {
    final json = await _api.getExplanation(
      studentResponseId: source.studentResponseId,
      academyUserId: source.academyUserId,
      questionNumber: source.question.questionNumber,
      subQuestionNumber: source.question.subQuestionNumber,
    );

    if (json == null) {
      return null;
    }

    return _mapper.fromGetResponse(json);
  }

  @override
  Future<ExplanationEntity> requestExplanation(
    ExplanationSource source, {
    required int requestedByUserId,
    required int academyId,
    required String answer,
  }) async {
    final json = await _api.postExplanation(
      studentResponseId: source.studentResponseId,
      userId: requestedByUserId,
      academyUserId: source.academyUserId,
      academyId: academyId,
      pageNumber: source.question.page,
      questionNumber: source.question.questionNumber,
      answer: answer,
    );

    return _mapper.fromPostResponse(json);
  }
}


