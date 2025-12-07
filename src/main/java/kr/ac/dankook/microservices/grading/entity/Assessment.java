package kr.ac.dankook.microservices.grading.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.UpdateTimestamp;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Getter
@Setter
@NoArgsConstructor
@EntityListeners(AuditingEntityListener.class)

public class Assessment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long assessId;

    private LocalDateTime assessDeadline;


    private Long assignerId;
    private Long assigneeId;
    private int assessStartPage;
    private int assessEndPage;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "book_id")
    private Book book;

    @CreatedDate
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;

    private String assessName;

    @Column(length = 1, nullable = false)
    private String assessType; // ('H'=Homework, 'L'='Learning)

    @Column(length = 1, nullable = false)
    private String assessStatus;


    // StudentResponse와 1:N 관계
    @OneToMany(mappedBy = "assessment", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<StudentResponse> studentResponses;
}
