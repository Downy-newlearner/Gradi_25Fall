package kr.ac.dankook.microservices.grading.entity;


import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor

public class StudentResponse {

    @Id
    private Long studentResponseId;

    @Column(name = "academy_user_id", nullable = false)
    private Long academyUserId;  // 외부 서비스 엔티티는 ID만 저장

    private int responseStartPage;

    private int responseEndPage;

    private int unrecognizedResponseCount;


    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assess_id")
    private Assessment assessment;

    @ManyToOne
    @JoinColumn(name = "book_id")
    private Book book;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;

}