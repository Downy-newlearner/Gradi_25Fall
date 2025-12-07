package kr.ac.dankook.microservices.academy.repository;

import io.micrometer.observation.ObservationFilter;
import kr.ac.dankook.microservices.academy.entity.AcademySchedule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface AcademyScheduleRepository extends JpaRepository<AcademySchedule, Long> {
    List<AcademySchedule> findByAcademyCode(String academyCode);

    Optional<AcademySchedule> findByAcademyCodeAndDayOfWeek(String academyCode, Integer dayOfWeek);
}
