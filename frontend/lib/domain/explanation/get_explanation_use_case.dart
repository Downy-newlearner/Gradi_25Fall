import 'explanation_entity.dart';
import 'explanation_repository.dart';
import 'explanation_source.dart';

/// 이미 생성된 해설을 조회하는 UseCase
class GetExplanationUseCase {
  final ExplanationRepository _repository;

  GetExplanationUseCase({required ExplanationRepository repository})
      : _repository = repository;

  Future<ExplanationEntity?> call(ExplanationSource source) {
    return _repository.getExplanation(source);
  }
}


