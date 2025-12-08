import 'explanation_entity.dart';
import 'explanation_repository.dart';
import 'explanation_source.dart';

/// 해설 생성을 요청하는 UseCase
class RequestExplanationUseCase {
  final ExplanationRepository _repository;

  RequestExplanationUseCase({required ExplanationRepository repository})
     : _repository = repository;

  Future<ExplanationEntity> call(
    ExplanationSource source, {
    required int requestedByUserId,
    required int academyId,
    required String answer,
  }) {
    return _repository.requestExplanation(
      source,
      requestedByUserId: requestedByUserId,
      academyId: academyId,
      answer: answer,
    );
  }
}


