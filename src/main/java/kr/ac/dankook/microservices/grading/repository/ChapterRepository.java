package kr.ac.dankook.microservices.grading.repository;

import kr.ac.dankook.microservices.grading.entity.Chapter;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ChapterRepository extends JpaRepository<Chapter, Long> {
    List<Chapter> findByBook_BookId(Long bookId);

    List<Chapter> findByBookBookId(Long bookId);

}
