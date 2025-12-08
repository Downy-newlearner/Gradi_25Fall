import 'dart:developer' as developer;
import '../../domain/chapter/chapter_entity.dart';
import '../../domain/chapter/chapter_repository.dart';
import 'chapter_api.dart';

/// 챕터 Repository 구현체
///
/// API 호출 및 DTO → Entity 변환을 담당합니다.
class ChapterRepositoryImpl implements ChapterRepository {
  ChapterRepositoryImpl({required ChapterApi api}) : _api = api;

  final ChapterApi _api;

  @override
  Future<List<ChapterEntity>> getChaptersByBookIdAndAcademyUserId(
    int bookId,
    int academyUserId,
  ) async {
    try {
      final apiResponses = await _api.fetchChapters(bookId, academyUserId);

      // API 응답 → 도메인 엔티티 변환
      return apiResponses
          .map(
            (response) => ChapterEntity(
              chapterId: response.chapterId,
              bookId: response.bookId,
              mainChapterNumber: response.mainChapterNumber,
              subChapterNumber: response.subChapterNumber,
              chapterName: response.chapterName,
              chapterStartPage: response.chapterStartPage,
              chapterEndPage: response.chapterEndPage,
              chapterStartQuestion: response.chapterStartQuestion,
              chapterEndQuestion: response.chapterEndQuestion,
              totalChapterQuestion: response.totalChapterQuestion,
              studentAnswerCount: response.studentAnswerCount,
            ),
          )
          .toList();
    } catch (e) {
      developer.log('❌ [ChapterRepository] API 호출 실패: $e');
      rethrow;
    }
  }

  @override
  Future<ChapterEntity> getChapterById(int chapterId) async {
    try {
      final apiResponse = await _api.fetchChapterById(chapterId);

      // API 응답 → 도메인 엔티티 변환
      return ChapterEntity(
        chapterId: apiResponse.chapterId,
        bookId: apiResponse.bookId,
        mainChapterNumber: apiResponse.mainChapterNumber,
        subChapterNumber: apiResponse.subChapterNumber,
        chapterName: apiResponse.chapterName,
        chapterStartPage: apiResponse.chapterStartPage,
        chapterEndPage: apiResponse.chapterEndPage,
        chapterStartQuestion: apiResponse.chapterStartQuestion,
        chapterEndQuestion: apiResponse.chapterEndQuestion,
        totalChapterQuestion: apiResponse.totalChapterQuestion,
        studentAnswerCount: apiResponse.studentAnswerCount,
      );
    } catch (e) {
      developer.log('❌ [ChapterRepository] 챕터 조회 실패: $e');
      rethrow;
    }
  }
}
