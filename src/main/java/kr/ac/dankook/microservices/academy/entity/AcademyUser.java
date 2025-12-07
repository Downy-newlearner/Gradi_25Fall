package kr.ac.dankook.microservices.academy.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

@Entity
@EntityListeners(AuditingEntityListener.class)
@Table(name = "academy_user")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AcademyUser {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "academy_user_id")
    private Long academyUserId;

    private Long academyId;  // ✅ Long 타입으로 유지

    private Long classId;

    private Long userId;

    private Long learnerId;

    private Character registerStatus;
}
