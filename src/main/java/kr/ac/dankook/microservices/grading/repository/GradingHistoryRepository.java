package kr.ac.dankook.microservices.grading.repository;

import kr.ac.dankook.microservices.grading.entity.GradingHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface GradingHistoryRepository extends JpaRepository<GradingHistory, Long> {

    @Query("""
        SELECT SUM(g.totalScore)
        FROM GradingHistory g
        WHERE g.studentResponse.academyUserId = :academyUserId
          AND g.studentResponse.studentResponseId = :studentResponseId
    """)
    Double getTotalScoreSum(
            @Param("academyUserId") Long academyUserId,
            @Param("studentResponseId") Long studentResponseId
    );

    @Query("""
        SELECT SUM(g.totalScore)
        FROM GradingHistory g
        WHERE g.studentResponse.academyUserId = :academyUserId
    """)
    Double getTotalScoreByAcademyUserId(@Param("academyUserId") Long academyUserId);

    List<GradingHistory> findByGraderId(Long graderId);

}
