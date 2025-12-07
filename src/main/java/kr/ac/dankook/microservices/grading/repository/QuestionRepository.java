package kr.ac.dankook.microservices.grading.repository;

import kr.ac.dankook.microservices.grading.entity.Question;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface QuestionRepository extends JpaRepository<Question, Long> {
    List<Question> findByChapterId(Long chapterId);

    Optional<Question> findByChapterIdAndQuestionNumberAndSubQuestionNumber(
            Long chapterId,
            int questionNumber,
            int subQuestionNumber
    );
}
