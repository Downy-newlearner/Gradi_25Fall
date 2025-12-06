import '../domain/section_image/section_image_entity.dart';
import 'section_image_api.dart';

/// Section 이미지 API 응답을 도메인 엔티티로 변환하는 Mapper
///
/// Data Layer 내부 유틸리티로, DTO → Entity 변환만 담당
class SectionImageMapper {
  /// API 응답을 도메인 엔티티로 변환
  SectionImageEntity fromApi(SectionImageApiResponse response) {
    // API 응답의 url은 이미 완성된 signed URL이므로 그대로 사용
    // (url에 query parameter가 포함되어 있어 key와 합치면 안 됨)
    final imageUrl = response.url;
    return SectionImageEntity(
      imageUrl: imageUrl,
    );
  }
}


