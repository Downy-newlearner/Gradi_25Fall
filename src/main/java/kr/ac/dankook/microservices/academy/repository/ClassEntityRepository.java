package kr.ac.dankook.microservices.academy.repository;

import kr.ac.dankook.microservices.academy.entity.ClassEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ClassEntityRepository  extends JpaRepository<ClassEntity, Long> {
}
