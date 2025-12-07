package kr.ac.dankook.microservices.grading.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "student_answer")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StudentAnswer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long studentAnswerId;

    private Long studentResponseId;

    private Long chapterId;

    private int page;

    private int questionNumber;

    private int subQuestionNumber;

    @Column(length = 2000)
    private String answer;

    private String section_url;

    private boolean isCorrect;

    private double score;
}
