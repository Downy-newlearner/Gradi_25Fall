import 'dart:developer' as developer;
import '../domain/section_image/section_image_entity.dart';
import '../domain/section_image/section_image_repository.dart';
import 'section_image_api.dart';
import 'section_image_mapper.dart';

/// Section 이미지 Repository 구현체
class SectionImageRepositoryImpl implements SectionImageRepository {
  final SectionImageApi _api;
  final SectionImageMapper _mapper;

  SectionImageRepositoryImpl({
    required SectionImageApi api,
    required SectionImageMapper mapper,
  })  : _api = api,
        _mapper = mapper;

  @override
  Future<SectionImageEntity?> getSectionImageUrl({
    required int academyUserId,
    required int studentResponseId,
    required int questionNumber,
    required int subQuestionNumber,
  }) async {
    try {
      // 1. API 호출
      final apiResponse = await _api.fetchSectionImageUrl(
        academyUserId: academyUserId,
        studentResponseId: studentResponseId,
        questionNumber: questionNumber,
        subQuestionNumber: subQuestionNumber,
      );

      // 2. Mapper로 엔티티 변환
      return _mapper.fromApi(apiResponse);
    } on SectionImageNotFoundException {
      // 404 에러는 "이미지 없음"으로 간주하여 null 반환 (정상 케이스)
      developer.log('ℹ️ [SectionImageRepository] 이미지 없음 (404) - 정상 케이스');
      return null;
    } catch (e) {
      // 그 외 에러는 예외로 전파
      developer.log('❌ [SectionImageRepository] API 호출 실패: $e');
      rethrow;
    }
  }
}


