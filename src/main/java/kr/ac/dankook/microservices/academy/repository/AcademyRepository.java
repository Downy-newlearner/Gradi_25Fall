package kr.ac.dankook.microservices.academy.repository;


import kr.ac.dankook.microservices.academy.entity.Academy;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface AcademyRepository extends JpaRepository<Academy, Long> {
    void deleteByAcademyCode(String code);

    boolean existsByAcademyCode(String code);


    @Query(value = "SELECT *, " +
            "(6371 * acos(cos(radians(:lat)) * cos(radians(a.academy_latitude)) * " +
            "cos(radians(a.academy_longitude) - radians(:lng)) + " +
            "sin(radians(:lat)) * sin(radians(a.academy_latitude)))) AS distance " +
            "FROM academy a " +
            "HAVING distance < :radius " +
            "ORDER BY distance ASC \n-- #pageable\n",
            countQuery = "SELECT count(*) FROM academy a",
            nativeQuery = true)
    List<Academy> findNearbyAcademiesWithPage(@Param("lat") double lat,
                                              @Param("lng") double lng,
                                              @Param("radius") double radius,
                                              Pageable pageable);

    Optional<Academy> findByAcademyCode(String academyCode);
}

