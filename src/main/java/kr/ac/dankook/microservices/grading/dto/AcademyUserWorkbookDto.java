package kr.ac.dankook.microservices.grading.dto;

import lombok.*;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
public class AcademyUserWorkbookDto {
    private Long academyUserId;
    private List<BookSolvedDto> books;
}
