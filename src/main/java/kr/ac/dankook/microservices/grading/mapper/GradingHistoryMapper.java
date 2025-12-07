package kr.ac.dankook.microservices.grading.mapper;

import kr.ac.dankook.microservices.grading.dto.GradingHistoryDto;
import kr.ac.dankook.microservices.grading.entity.GradingHistory;
import kr.ac.dankook.microservices.grading.entity.StudentResponse;

public class GradingHistoryMapper {

    public static GradingHistoryDto toDto(GradingHistory entity) {
        if (entity == null) return null;

        return GradingHistoryDto.builder()
                .history_id(entity.getHistoryId())
                .student_response_id(entity.getStudentResponse() != null ? entity.getStudentResponse().getStudentResponseId() : null)
                .total_score(entity.getTotalScore())
                .grade_at(entity.getGradeAt())
                .grader_id(entity.getGraderId())
                .build();
    }

    public static GradingHistory toEntity(GradingHistoryDto dto, StudentResponse studentResponse) {
        if (dto == null) return null;

        GradingHistory entity = new GradingHistory();
        entity.setHistoryId(dto.getHistory_id());
        entity.setStudentResponse(studentResponse);
        entity.setTotalScore(dto.getTotal_score());
        entity.setGradeAt(dto.getGrade_at());
        entity.setGraderId(dto.getGrader_id());
        return entity;
    }
}
