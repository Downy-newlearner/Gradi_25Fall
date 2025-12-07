package kr.ac.dankook.microservices.grading.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter
@Setter
@NoArgsConstructor
public class Question {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long questionId;

    private Long chapterId;
    private Integer page;
    private Double point;
    private Integer questionNumber;
    private Integer subQuestionNumber;
    private String answer;
    private Integer answerCount;
}
