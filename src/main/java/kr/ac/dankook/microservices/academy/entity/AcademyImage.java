package kr.ac.dankook.microservices.academy.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;

import java.time.LocalDateTime;

@Entity
@Getter
@Setter
@NoArgsConstructor
public class AcademyImage {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long academyImageId;

    // 대표 사진 여부
    private boolean isMainImage = false;

    private String academyCode;

    private String academyImageUrl;


    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
