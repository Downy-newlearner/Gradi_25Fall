import '../../domain/explanation/explanation_entity.dart';
import '../../domain/explanation/explanation_repository.dart';
import '../../domain/explanation/explanation_source.dart';
import '../../domain/explanation/get_explanation_use_case.dart';
import '../../domain/explanation/request_explanation_use_case.dart';
import '../../services/auth_service.dart';
import '../../services/academy_service.dart';
import '../../utils/app_logger.dart';

/// 해설 조회/생성 결과
class ExplanationLoadResult {
  final ExplanationEntity? explanation;
  final bool requestPerformed;

  const ExplanationLoadResult({
    required this.explanation,
    required this.requestPerformed,
  });
}

/// 해설 조회/생성 흐름을 오케스트레이션하는 Application Service
class ExplanationService {
  final ExplanationRepository _repository;
  final GetExplanationUseCase _getExplanationUseCase;
  final RequestExplanationUseCase _requestExplanationUseCase;
  final AuthService _authService;
  final AcademyService _academyService;

  ExplanationService({
    required ExplanationRepository repository,
    required GetExplanationUseCase getExplanationUseCase,
    required RequestExplanationUseCase requestExplanationUseCase,
    required AuthService authService,
    required AcademyService academyService,
  }) : _repository = repository,
       _getExplanationUseCase = getExplanationUseCase,
       _requestExplanationUseCase = requestExplanationUseCase,
       _authService = authService,
       _academyService = academyService;

  /// 이미 생성된 해설만 조회합니다.
  ///
  /// 존재하지 않으면 null을 반환하며, POST 요청은 절대 수행하지 않습니다.
  Future<ExplanationEntity?> loadExistingExplanation(
    ExplanationSource source,
  ) async {
    return _getExplanationUseCase(source);
  }

  /// 해설을 불러오거나, 없으면 생성 요청 후 다시 불러옵니다.
  ///
  /// [ExplanationLoadResult.requestPerformed]가 true이면
  /// 이번 호출에서 실제로 POST 요청이 수행되었음을 의미합니다.
  ///
  /// 흐름:
  /// 1. GET (Redis에서 LLM 해설 가져오기) - 404/400이어도 계속 진행
  /// 2. GET (정답 가져오기)
  /// 3. POST (해설 생성 요청)
  /// 4. GET (Redis에서 LLM 해설 가져오기)
  Future<ExplanationLoadResult> loadOrRequestExplanation(
    ExplanationSource source,
  ) async {
    appLog('[explanation] ========== 해설 요청 흐름 시작 ==========');
    appLog(
      '[explanation] source: studentResponseId=${source.studentResponseId}, academyUserId=${source.academyUserId}, question=${source.question.questionNumber}, subQuestion=${source.question.subQuestionNumber}',
    );

    // 1) 캐시/기존 해설 조회 (Redis에서 LLM 해설 가져오기)
    // 404/400이어도 null을 반환하고 계속 진행
    appLog('[explanation] [1/4] GET (Redis에서 LLM 해설 가져오기) 시작');
    final existing = await _getExplanationUseCase(source);

    if (existing != null) {
      appLog(
        '[explanation] [1/4] GET (Redis에서 LLM 해설 가져오기) 완료: 해설 존재, POST 생략',
      );
      appLog('[explanation] ========== 해설 요청 흐름 종료 (기존 해설 반환) ==========');
      return ExplanationLoadResult(
        explanation: existing,
        requestPerformed: false,
      );
    }

    appLog(
      '[explanation] [1/4] GET (Redis에서 LLM 해설 가져오기) 완료: 해설 없음 (404/400), 다음 단계 진행',
    );

    // 2) 학생 답안 정보 조회 (정답 가져오기)
    // 첫 번째 GET에서 404/400이 나왔어도 정상적으로 진행
    appLog('[explanation] [2/4] GET (정답 가져오기) 시작');
    final studentAnswerInfo = await _repository.findStudentAnswer(source);
    appLog(
      '[explanation] [2/4] GET (정답 가져오기) 완료: answer=${studentAnswerInfo.answer}',
    );

    // 3) 요청자 ID 확보
    final userIdStr = await _authService.getUserId();
    if (userIdStr == null) {
      throw Exception('사용자 정보를 찾을 수 없습니다. 다시 로그인해 주세요.');
    }
    final userId = int.tryParse(userIdStr) ?? 0;
    if (userId == 0) {
      throw Exception('유효하지 않은 사용자 ID입니다.');
    }

    // 4) academyId 가져오기 (학원 목록에서 academyUserId로 찾기)
    final academies = await _academyService.loadAcademiesFromCache();
    if (academies == null || academies.isEmpty) {
      throw Exception('학원 정보를 찾을 수 없습니다.');
    }

    final academy = academies.firstWhere(
      (a) => a.academy_user_id == source.academyUserId,
      orElse: () => academies.first,
    );

    final academyId = academy.academy_id;
    if (academyId == null) {
      throw Exception('학원 ID를 찾을 수 없습니다.');
    }

    appLog(
      '[explanation] POST 준비: userId=$userId, academyId=$academyId, answer=${studentAnswerInfo.answer}',
    );

    // 5) 해설 생성 요청 (POST)
    appLog('[explanation] [3/4] POST (해설 생성 요청) 시작');
    await _requestExplanationUseCase(
      source,
      requestedByUserId: userId,
      academyId: academyId,
      answer: studentAnswerInfo.answer,
    );
    appLog('[explanation] [3/4] POST (해설 생성 요청) 완료');

    // 6) 다시 조회 (Redis에서 LLM 해설 가져오기)
    // 생성 후 캐시에 반영되었다는 가정
    appLog('[explanation] [4/4] GET (Redis에서 LLM 해설 가져오기) 시작');
    final after = await _getExplanationUseCase(source);
    appLog(
      '[explanation] [4/4] GET (Redis에서 LLM 해설 가져오기) 완료: ${after != null ? "해설 존재" : "해설 없음"}',
    );
    appLog('[explanation] ========== 해설 요청 흐름 종료 ==========');

    return ExplanationLoadResult(explanation: after, requestPerformed: true);
  }
}
