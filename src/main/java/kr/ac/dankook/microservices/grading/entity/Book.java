package kr.ac.dankook.microservices.grading.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity

@Getter
@Setter
@NoArgsConstructor
public class Book {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long bookId;
    private String bookName;
    private int bookPublicationYear;
    private int bookPage;
    private String bookSemester;
    private String bookImageUrl;

}
