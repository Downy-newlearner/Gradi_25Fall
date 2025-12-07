package kr.ac.dankook.microservices.grading.controller;

import kr.ac.dankook.microservices.grading.dto.ChapterDto;
import kr.ac.dankook.microservices.grading.dto.QuestionDto;
import kr.ac.dankook.microservices.grading.service.ChapterService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/chapter")
@RequiredArgsConstructor
public class ChapterController {
    private final ChapterService chapterService;


    @GetMapping("/book/{bookId}")
    public ResponseEntity<List<ChapterDto>> getChaptersByBookId(@PathVariable Long bookId) {
        List<ChapterDto> chapters = chapterService.getChaptersByBookId(bookId);
        return ResponseEntity.ok(chapters);
    }

    @GetMapping("/{chapterId}/questions")
    public ResponseEntity<List<QuestionDto>> getQuestionsByChapterId(
            @PathVariable Long chapterId
    ) {
        return ResponseEntity.ok(
                chapterService.getQuestionsByChapterId(chapterId)
        );
    }



    @GetMapping("/book/{bookId}/user/{academyUserId}")
    public ResponseEntity<List<ChapterDto>> getChaptersByBookIdAndUser(
            @PathVariable Long bookId,
            @PathVariable Long academyUserId
    ) {
        return ResponseEntity.ok(
                chapterService.getChaptersByBookIdAndUser(bookId, academyUserId)
        );
    }


    @GetMapping("/{id}")
    public ResponseEntity<ChapterDto> getById(@PathVariable Long id) {
        ChapterDto dto = chapterService.getById(id);
        return dto != null ? ResponseEntity.ok(dto) : ResponseEntity.notFound().build();
    }

    @PostMapping
    public ResponseEntity<ChapterDto> create(@RequestBody ChapterDto dto) {
        return ResponseEntity.ok(chapterService.create(dto));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ChapterDto> update(@PathVariable Long id, @RequestBody ChapterDto dto) {
        ChapterDto updated = chapterService.update(id, dto);
        return updated != null ? ResponseEntity.ok(updated) : ResponseEntity.notFound().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        chapterService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
