package kr.ac.dankook.microservices.academy.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalTime;
import java.time.LocalDateTime;

@Entity
@Table(
        name = "academy_schedule",
        uniqueConstraints = @UniqueConstraint(columnNames = {"academyCode", "dayOfWeek"})
)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AcademySchedule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id; // 내부 PK, JPA용

    @Column(nullable = false, length = 50)
    private String academyCode; // 학원 고유 코드

    @Column(nullable = false)
    private Integer dayOfWeek; // 0=월, 1=화, … 6=일

    @Column(nullable = false)
    private LocalTime startTime;

    @Column(nullable = false)
    private LocalTime endTime;



}
