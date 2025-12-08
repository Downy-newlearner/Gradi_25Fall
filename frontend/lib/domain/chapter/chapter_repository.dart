import 'chapter_entity.dart';

/// 챕터 Repository 인터페이스
///
/// 도메인 레이어에서 데이터 레이어에 의존하지 않도록 추상화합니다.
abstract class ChapterRepository {
  /// bookId와 academyUserId로 챕터 목록 조회
  ///
  /// [bookId]: 문제집 ID
  /// [academyUserId]: 학원 사용자 ID
  ///
  /// 반환: 챕터 엔티티 리스트 (정렬되지 않은 상태)
  Future<List<ChapterEntity>> getChaptersByBookIdAndAcademyUserId(
    int bookId,
    int academyUserId,
  );

  /// chapterId로 단일 챕터 정보 조회
  ///
  /// [chapterId]: 챕터 ID
  ///
  /// 반환: 챕터 엔티티
  Future<ChapterEntity> getChapterById(int chapterId);
}
