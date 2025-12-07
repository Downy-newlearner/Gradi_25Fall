package kr.ac.dankook.microservices.grading.mapper;

import kr.ac.dankook.microservices.grading.dto.ChapterDto;
import kr.ac.dankook.microservices.grading.entity.Book;
import kr.ac.dankook.microservices.grading.entity.Chapter;

import java.util.List;
import java.util.stream.Collectors;

public class ChapterMapper {

    /** 단건 변환 + answerCount 포함 */
    public static ChapterDto toDto(Chapter chapter, long answerCount) {
        if (chapter == null) return null;

        return ChapterDto.builder()
                .chapter_id(chapter.getChapterId())
                .book_id(chapter.getBook() != null ? chapter.getBook().getBookId() : null)
                .main_chapter_number(chapter.getMainChapterNumber())
                .sub_chapter_number(chapter.getSubChapterNumber())
                .chapter_name(chapter.getChapterName())
                .total_chapter_question(chapter.getTotalChapterQuestion())
                .chapter_start_page(chapter.getChapterStartPage())
                .chapter_end_page(chapter.getChapterEndPage())
                .chapter_start_question(chapter.getChapterStartQuestion())
                .chapter_end_question(chapter.getChapterEndQuestion())
                .student_answer_count(answerCount)
                .build();
    }

    /** DTO → Entity 변환 */
    public static Chapter toEntity(ChapterDto dto, Book book) {
        if (dto == null) return null;

        Chapter chapter = new Chapter();
        chapter.setChapterId(dto.getChapter_id());
        chapter.setBook(book);
        chapter.setMainChapterNumber(dto.getMain_chapter_number());
        chapter.setSubChapterNumber(dto.getSub_chapter_number());
        chapter.setChapterName(dto.getChapter_name());
        chapter.setChapterStartPage(dto.getChapter_start_page());
        chapter.setChapterEndPage(dto.getChapter_end_page());
        chapter.setChapterStartQuestion(dto.getChapter_start_question());
        chapter.setChapterEndQuestion(dto.getChapter_end_question());
        chapter.setTotalChapterQuestion(dto.getTotal_chapter_question());

        return chapter;
    }

    /** Entity Update */
    public static void updateEntityFromDto(ChapterDto dto, Chapter entity, Book book) {
        if (book != null) {
            entity.setBook(book);
        }
        entity.setMainChapterNumber(dto.getMain_chapter_number());
        entity.setSubChapterNumber(dto.getSub_chapter_number());
        entity.setChapterName(dto.getChapter_name());
        entity.setChapterStartPage(dto.getChapter_start_page());
        entity.setChapterEndPage(dto.getChapter_end_page());
        entity.setChapterStartQuestion(dto.getChapter_start_question());
        entity.setChapterEndQuestion(dto.getChapter_end_question());
        entity.setTotalChapterQuestion(dto.getTotal_chapter_question());
    }

    /** answerCount는 0으로 기본 적용한 리스트 변환 */
    public static List<ChapterDto> toDtoList(List<Chapter> chapters) {
        return chapters.stream()
                .map(ch -> toDto(ch, 0L))   // 기본값 0
                .collect(Collectors.toList());
    }
}
