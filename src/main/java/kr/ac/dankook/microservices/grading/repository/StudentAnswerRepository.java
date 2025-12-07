package kr.ac.dankook.microservices.grading.repository;

import kr.ac.dankook.microservices.grading.entity.Assessment;
import kr.ac.dankook.microservices.grading.entity.StudentAnswer;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface StudentAnswerRepository extends JpaRepository<StudentAnswer, Long> {
    List<StudentAnswer> findByStudentResponseId(Long studentResponseId);

    Long countByChapterIdAndStudentResponseIdIn(Long chapterId, List<Long> responseIds);
    List<StudentAnswer> findByStudentResponseIdInAndChapterId(List<Long> studentResponseIds, Long chapterId);

    List<StudentAnswer> findByStudentResponseIdIn(List<Long> responseIds);



    Optional<StudentAnswer> findByStudentResponseIdAndQuestionNumberAndSubQuestionNumber(Long studentResponseId, int questionNumber, int subQuestionNumber);
}



