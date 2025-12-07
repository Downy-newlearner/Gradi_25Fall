package kr.ac.dankook.microservices.grading.mapper;

import kr.ac.dankook.microservices.grading.dto.AssessmentDto;
import kr.ac.dankook.microservices.grading.entity.Assessment;
import kr.ac.dankook.microservices.grading.entity.Book;

public class AssessmentMapper {

    // Entity → DTO
    public static AssessmentDto toDto(Assessment entity) {
        if (entity == null) return null;

        Book book = entity.getBook();

        return AssessmentDto.builder()
                .assess_id(entity.getAssessId())
                .assigner_id(entity.getAssignerId())
                .assignee_id(entity.getAssigneeId())
                .assess_start_page(entity.getAssessStartPage())
                .assess_end_page(entity.getAssessEndPage())
                .assess_deadline(entity.getAssessDeadline())
                .assess_name(entity.getAssessName())
                .assess_type(entity.getAssessType())
                .assess_status(entity.getAssessStatus())
                .book_id(book != null ? book.getBookId() : null)
                .build();
    }

    // DTO → Entity
    public static Assessment toEntity(AssessmentDto dto, Book book) {
        if (dto == null) return null;

        Assessment entity = new Assessment();
        entity.setAssessId(dto.getAssess_id());
        entity.setAssignerId(dto.getAssigner_id());
        entity.setAssigneeId(dto.getAssignee_id());
        entity.setAssessStartPage(dto.getAssess_start_page());
        entity.setAssessEndPage(dto.getAssess_end_page());
        entity.setAssessDeadline(dto.getAssess_deadline());
        entity.setAssessName(dto.getAssess_name());
        entity.setAssessType(dto.getAssess_type());
        entity.setAssessStatus(dto.getAssess_status());

        // ★ Book 객체를 직접 받아서 설정하는 방식으로 수정
        entity.setBook(book);

        return entity;
    }
}
