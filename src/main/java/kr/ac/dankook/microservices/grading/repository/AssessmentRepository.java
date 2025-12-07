package kr.ac.dankook.microservices.grading.repository;

import kr.ac.dankook.microservices.grading.entity.Assessment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface AssessmentRepository extends JpaRepository<Assessment, Long> {
    List<Assessment> findByAssigneeIdAndAssignerId(Long academyUserId, Long bookId);

    @Query("SELECT a FROM Assessment a JOIN a.studentResponses sr WHERE a.assigneeId = :assigneeId AND sr.book.bookId = :bookId")
    List<Assessment> findByAssigneeIdAndBookId(@Param("assigneeId") Long assigneeId,
                                               @Param("bookId") Long bookId);

    @Query("SELECT a FROM Assessment a " +
            "LEFT JOIN FETCH a.book " +
            "LEFT JOIN FETCH a.studentResponses " +
            "WHERE a.assigneeId = :assigneeId")
    List<Assessment> findAllByAssigneeIdWithResponses(@Param("assigneeId") Long assigneeId);


    @Query("SELECT a FROM Assessment a " +
            "LEFT JOIN FETCH a.book " +
            "LEFT JOIN FETCH a.studentResponses " +
            "WHERE a.assigneeId = :assigneeId " +
            "AND a.assessDeadline BETWEEN :startOfMonth AND :endOfMonth")
    List<Assessment> findAllByAssigneeIdWithDeadlineRange(
            @Param("assigneeId") Long assigneeId,
            @Param("startOfMonth") LocalDateTime startOfMonth,
            @Param("endOfMonth") LocalDateTime endOfMonth
    );





}
