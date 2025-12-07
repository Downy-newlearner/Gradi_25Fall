package kr.ac.dankook.microservices.grading.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChapterDto {
    private Long chapter_id;
    private Long book_id;
    private int main_chapter_number;
    private int sub_chapter_number;
    private String chapter_name;

    private int chapter_start_page;
    private int chapter_end_page;
    private int chapter_start_question;
    private int chapter_end_question;
    private int total_chapter_question;

    private Long student_answer_count;

}
