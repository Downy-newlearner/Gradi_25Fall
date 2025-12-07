package kr.ac.dankook.microservices.academy.dto;

import lombok.*;

import java.time.LocalTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AcademyScheduleDto {

    private Long id;
    private String academy_code; // FK용
    private Integer day_of_week;
    private LocalTime start_time;
    private LocalTime end_time;
}
