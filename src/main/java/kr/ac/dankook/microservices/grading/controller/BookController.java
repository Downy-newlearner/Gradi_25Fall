// BookController.java
package kr.ac.dankook.microservices.grading.controller;

import kr.ac.dankook.microservices.grading.dto.BookDto;
import kr.ac.dankook.microservices.grading.entity.Book;
import kr.ac.dankook.microservices.grading.service.BookService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/book")
@RequiredArgsConstructor
public class BookController {

    @Autowired
    private final BookService bookService;

    @GetMapping
    public ResponseEntity<List<BookDto>> getAll() {
        return ResponseEntity.ok(bookService.getAllBooks());
    }


    @GetMapping("/{id}")
    public ResponseEntity<BookDto> getBookById(@PathVariable Long id) {
        BookDto dto = bookService.getBookById(id);
        return dto != null ? ResponseEntity.ok(dto) : ResponseEntity.notFound().build();
    }


    @PostMapping
    public ResponseEntity<BookDto> create(@RequestBody BookDto dto) {
        return ResponseEntity.ok(bookService.createBook(dto));
    }

    @PutMapping("/{id}")
    public ResponseEntity<BookDto> update(@PathVariable Long id, @RequestBody BookDto dto) {
        BookDto updated = bookService.updateBook(id, dto);
        return updated != null ? ResponseEntity.ok(updated) : ResponseEntity.notFound().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        bookService.deleteBook(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/chapters")
    public ResponseEntity<List<BookDto>> getBooksByChapterIds(@RequestParam List<Long> chapterIds) {
        List<BookDto> books = bookService.getBooksByChapterIds(chapterIds);
        return ResponseEntity.ok(books);
    }



}
