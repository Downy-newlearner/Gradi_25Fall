package kr.ac.dankook.microservices.academy.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import java.time.LocalDateTime;
import java.util.Set;

@Entity
@Getter
@Setter
@NoArgsConstructor
public class Academy {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long academyId;

    private String academyName;

    @Column(unique = true)
    private String academyCode;

    private String academyEmail;
    private String academyPhone;


    private String academyWebsite;

    @Column(length = 500)
    private String academyDescription;

    private String academyRoadAddress;     // 도로명 주소
    private String academyDetailAddress;    // 건물명 + 층 정보
    private double academyLatitude;        // 위도
    private double academyLongitude;       // 경도



    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
