package kr.ac.dankook.microservices.grading.mapper;

import kr.ac.dankook.microservices.grading.dto.BookDto;
import kr.ac.dankook.microservices.grading.entity.Book;

public class BookMapper {

    public static BookDto toDto(Book book) {
        if (book == null) return null;

        return BookDto.builder()
                .book_id(book.getBookId())
                .book_name(book.getBookName())
                .book_publication_year(book.getBookPublicationYear())
                .book_semester(book.getBookSemester())
                .book_page(book.getBookPage())
                .book_image_url(book.getBookImageUrl())
                .build();
    }

    public static Book toEntity(BookDto dto) {
        if (dto == null) return null;

        Book book = new Book();
        book.setBookId(dto.getBook_id());
        book.setBookName(dto.getBook_name());
        book.setBookPublicationYear(dto.getBook_publication_year());
        book.setBookSemester(dto.getBook_semester());
        book.setBookPage(dto.getBook_page());
        book.setBookImageUrl(dto.getBook_image_url());
        return book;
    }
}
