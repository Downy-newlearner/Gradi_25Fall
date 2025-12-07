package kr.ac.dankook.microservices.academy.repository;

import kr.ac.dankook.microservices.academy.entity.AcademyUser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface AcademyUserRepository extends JpaRepository<AcademyUser, Long> {

    List<AcademyUser> findByUserId(Long userId);

    // ✅ userId 기준으로 중복 학원 제거 (DISTINCT)
    @Query("SELECT DISTINCT a FROM AcademyUser a WHERE a.userId = :userId")
    List<AcademyUser> findDistinctAcademyByUserId(@Param("userId") Long userId);



    List<AcademyUser> findDistinctByUserId(Long userId);


    Optional<AcademyUser> findByUserIdAndAcademyId(Long userId, Long academyId);
}
