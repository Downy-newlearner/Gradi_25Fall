package kr.ac.dankook.microservices.grading.dto;

import kr.ac.dankook.microservices.grading.dto.StudentResponseDto;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
public class BookSolvedDto {
    private Long book_id;
    private String book_name;
    private int book_page;
    private String book_semester;
    private String book_image_url;
    private int total_solved_pages;
    private LocalDateTime latest_updated_at;



}
