import 'section_image_entity.dart';

/// Section 이미지 Repository 인터페이스
abstract class SectionImageRepository {
  /// Section 이미지 URL 조회
  ///
  /// [academyUserId]: 학원 사용자 ID
  /// [studentResponseId]: 학생 응답 ID
  /// [questionNumber]: 문제 번호
  /// [subQuestionNumber]: 소문제 번호 (0이면 메인 문제)
  ///
  /// 반환: Section 이미지 엔티티 (이미지가 없으면 null)
  ///
  /// 참고: 이미지가 없는 경우는 정상적인 케이스로 간주하여 null을 반환합니다.
  Future<SectionImageEntity?> getSectionImageUrl({
    required int academyUserId,
    required int studentResponseId,
    required int questionNumber,
    required int subQuestionNumber,
  });
}


