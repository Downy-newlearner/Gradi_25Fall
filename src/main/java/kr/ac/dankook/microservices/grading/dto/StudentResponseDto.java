package kr.ac.dankook.microservices.grading.dto;

import lombok.*;

import java.time.LocalDateTime;

@Data
@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class StudentResponseDto {
    private Long student_response_id;
    private Long academy_user_id;
    private Long assess_id; // Assessment 엔티티 대신 ID만 노출
    private Long book_id;       // Book 엔티티 대신 ID만 노출
    private String book_name;       // Book 엔티티 대신 ID만 노출
    private String book_image_url;       // Book 엔티티 대신 ID만 노출
    private int response_start_page;
    private int response_end_page;
    private int unrecognized_response_count;       // Book 엔티티 대신 ID만 노출
    private LocalDateTime created_at;       // Book 엔티티 대신 ID만 노출
    private LocalDateTime updated_at;       // Book 엔티티 대신 ID만 노출

    public StudentResponseDto(Long studentResponseId, LocalDateTime createdAt) {
        this.student_response_id = studentResponseId;
        this.created_at = createdAt;
    }


}
