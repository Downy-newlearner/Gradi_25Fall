package kr.ac.dankook.microservices.grading.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BookDto {
    private Long book_id;
    private String book_name;
    private int book_publication_year;
    private int book_page;
    private String book_semester;
    private String book_image_url;

}

