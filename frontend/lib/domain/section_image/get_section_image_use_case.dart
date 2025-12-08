import 'section_image_entity.dart';
import 'section_image_repository.dart';

/// Section 이미지 URL을 조회하는 UseCase
class GetSectionImageUseCase {
  final SectionImageRepository _repository;

  GetSectionImageUseCase({
    required SectionImageRepository repository,
  }) : _repository = repository;

  /// Section 이미지 URL 조회
  ///
  /// 반환: 이미지가 있으면 SectionImageEntity, 없으면 null
  Future<SectionImageEntity?> call({
    required int academyUserId,
    required int studentResponseId,
    required int questionNumber,
    required int subQuestionNumber,
  }) {
    return _repository.getSectionImageUrl(
      academyUserId: academyUserId,
      studentResponseId: studentResponseId,
      questionNumber: questionNumber,
      subQuestionNumber: subQuestionNumber,
    );
  }
}


