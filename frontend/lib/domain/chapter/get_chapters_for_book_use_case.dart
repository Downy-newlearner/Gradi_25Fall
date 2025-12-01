import 'chapter_entity.dart';
import 'chapter_repository.dart';

/// 문제집의 챕터 목록 조회 UseCase
///
/// 비즈니스 규칙:
/// 1. 챕터를 mainChapterNumber, subChapterNumber 순으로 정렬
/// 2. 도메인 엔티티로 변환
class GetChaptersForBookUseCase {
  final ChapterRepository _repository;

  GetChaptersForBookUseCase({required ChapterRepository repository})
    : _repository = repository;

  /// 챕터 목록 조회 및 정렬
  ///
  /// [bookId]: 문제집 ID
  /// [academyUserId]: 학원 사용자 ID
  ///
  /// 반환: 정렬된 챕터 엔티티 리스트
  Future<List<ChapterEntity>> call({
    required int bookId,
    required int academyUserId,
  }) async {
    final chapters = await _repository.getChaptersByBookIdAndAcademyUserId(
      bookId,
      academyUserId,
    );

    // 비즈니스 규칙: mainChapterNumber 우선, 그 다음 subChapterNumber로 정렬
    // ⚠️ Repository가 캐싱된 리스트를 반환할 수 있으므로, 복사 후 정렬
    final sorted = List<ChapterEntity>.from(chapters);
    sorted.sort((a, b) {
      final mainCompare = a.mainChapterNumber.compareTo(b.mainChapterNumber);
      if (mainCompare != 0) return mainCompare;
      return a.subChapterNumber.compareTo(b.subChapterNumber);
    });

    return sorted;
  }
}
