package kr.ac.dankook.microservices.academy.repository;

import io.micrometer.observation.ObservationFilter;
import kr.ac.dankook.microservices.academy.entity.Student;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface StudentRepository extends JpaRepository<Student, Long> {
    Optional<Student> findByUserId(Long userId);
}
