package kr.ac.dankook.microservices.academy.dto;

import lombok.*;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AcademyWithScheduleDto {

    private AcademyDto academy;
    private List<AcademyScheduleDto> schedules;
}
