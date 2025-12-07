package kr.ac.dankook.microservices.academy.mapper;

import kr.ac.dankook.microservices.academy.dto.AcademyScheduleDto;
import kr.ac.dankook.microservices.academy.entity.AcademySchedule;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.stream.Collectors;

@Component
public class AcademyScheduleMapper {

    public static AcademyScheduleDto toDto(AcademySchedule schedule) {
        if (schedule == null) return null;
        return AcademyScheduleDto.builder()
                .id(schedule.getId())
                .academy_code(schedule.getAcademyCode())
                .day_of_week(schedule.getDayOfWeek())
                .start_time(schedule.getStartTime())
                .end_time(schedule.getEndTime())
                .build();
    }

    public AcademySchedule toEntity(AcademyScheduleDto dto) {
        if (dto == null) return null;
        return AcademySchedule.builder()
                .id(dto.getId())
                .academyCode(dto.getAcademy_code())
                .dayOfWeek(dto.getDay_of_week())
                .startTime(dto.getStart_time())
                .endTime(dto.getEnd_time())
                .build();
    }

    public void updateEntity(AcademyScheduleDto dto, AcademySchedule schedule) {
        if (dto.getDay_of_week() != null) schedule.setDayOfWeek(dto.getDay_of_week());
        if (dto.getStart_time() != null) schedule.setStartTime(dto.getStart_time());
        if (dto.getEnd_time() != null) schedule.setEndTime(dto.getEnd_time());
        if (dto.getAcademy_code() != null) schedule.setAcademyCode(dto.getAcademy_code());
    }

    // List<엔티티> → List<DTO>
    public static List<AcademyScheduleDto> toDtoList(List<AcademySchedule> schedules) {
        return schedules.stream()
                .map(AcademyScheduleMapper::toDto)
                .collect(Collectors.toList());
    }

}
