package kr.ac.dankook.microservices.storage.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class BookImageDto {
    private Long book_id;
    private String image_url;
}
