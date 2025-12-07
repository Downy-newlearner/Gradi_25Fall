package kr.ac.dankook.microservices.grading.service;

import kr.ac.dankook.microservices.grading.dto.BookDto;
import kr.ac.dankook.microservices.grading.entity.Book;
import kr.ac.dankook.microservices.grading.entity.Chapter;
import kr.ac.dankook.microservices.grading.mapper.BookMapper;
import kr.ac.dankook.microservices.grading.repository.BookRepository;
import kr.ac.dankook.microservices.grading.repository.ChapterRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BookService {

    private final ChapterRepository chapterRepository;
    private final BookRepository bookRepository;

    public List<BookDto> getAllBooks() {
        return bookRepository.findAll()
                .stream()
                .map(BookMapper::toDto)
                .collect(Collectors.toList());
    }

    public BookDto getBookById(Long id) {
        return bookRepository.findById(id)
                .map(BookMapper::toDto)
                .orElse(null);
    }

    public BookDto createBook(BookDto dto) {
        Book book = BookMapper.toEntity(dto);
        Book saved = bookRepository.save(book);
        return BookMapper.toDto(saved);
    }

    public BookDto updateBook(Long id, BookDto dto) {
        return bookRepository.findById(id)
                .map(book -> {
                    book.setBookName(dto.getBook_name());
                    return BookMapper.toDto(bookRepository.save(book));
                })
                .orElse(null);
    }

    public void deleteBook(Long id) {
        bookRepository.deleteById(id);
    }




    public Optional<Book> getBookByChapterId(Long chapterId) {
        return chapterRepository.findById(chapterId)
                .map(Chapter::getBook);
    }

    public List<BookDto> getBooksByChapterIds(List<Long> chapterIds) {
        List<Chapter> chapters = chapterRepository.findAllById(chapterIds);
        return chapters.stream()
                .map(Chapter::getBook)
                .distinct()
                .map(BookMapper::toDto)
                .collect(Collectors.toList());
    }




}
