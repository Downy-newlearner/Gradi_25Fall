package kr.ac.dankook.microservices.grading.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity

@Getter
@Setter
@NoArgsConstructor
public class Chapter {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long chapterId;
    private int MainChapterNumber;
    private int subChapterNumber;
    private int chapterStartPage;
    private int chapterEndPage;
    private int chapterStartQuestion;
    private int chapterEndQuestion;

    private String chapterName;
    private int totalChapterQuestion;

    // ✅ Chapter → Book (N:1)
    @ManyToOne
    @JoinColumn(name = "book_id", nullable = false)
    private Book book;


}
