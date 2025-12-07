package kr.ac.dankook.microservices.academy.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class AcademyUserClassDto {
    private Long academyUserId;
    private String className;
}
