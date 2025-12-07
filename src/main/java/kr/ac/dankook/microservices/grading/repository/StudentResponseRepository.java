package kr.ac.dankook.microservices.grading.repository;

import kr.ac.dankook.microservices.grading.entity.Book;
import kr.ac.dankook.microservices.grading.entity.StudentResponse;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface StudentResponseRepository extends JpaRepository<StudentResponse, Long> {
    List<StudentResponse> findByAcademyUserId(Long academyUserId);


    List<StudentResponse> findByAcademyUserIdIn(List<Long> academyUserIds);


    List<StudentResponse> findByAcademyUserIdAndBook_BookId(Long academyUserId, Long bookId);

    List<StudentResponse> findByAcademyUserIdInAndCreatedAtBetween(List<Long> academyUserIds, LocalDateTime startDate, LocalDateTime endDate);
}
