package kr.ac.dankook.microservices.grading.mapper;

import kr.ac.dankook.microservices.grading.dto.StudentResponseDto;
import kr.ac.dankook.microservices.grading.entity.Assessment;
import kr.ac.dankook.microservices.grading.entity.Book;
import kr.ac.dankook.microservices.grading.entity.Chapter;
import kr.ac.dankook.microservices.grading.entity.StudentResponse;

import java.util.List;

public class StudentResponseMapper {
    // StudentResponseDto -> StudentResponse
    public static StudentResponse toEntity(StudentResponseDto dto, Assessment assessment, Book book) {
        if (dto == null) return null;

        StudentResponse entity = new StudentResponse();
        // ID는 필요 시 설정
        entity.setStudentResponseId(dto.getStudent_response_id());

        entity.setAcademyUserId(dto.getAcademy_user_id());
        entity.setAssessment(assessment);
        entity.setBook(book);
        entity.setCreatedAt(dto.getCreated_at());
        entity.setUpdatedAt(dto.getUpdated_at());

        return entity;
    }
    // Entity → DTO
    public static StudentResponseDto toDto(StudentResponse r) {
        if (r == null) return null;

        return StudentResponseDto.builder()
                .student_response_id(r.getStudentResponseId())
                .academy_user_id(r.getAcademyUserId())
                .assess_id(r.getAssessment() != null ? r.getAssessment().getAssessId() : null)
                .book_id(r.getBook() != null ? r.getBook().getBookId() : null)
                .book_name(r.getBook() != null ? r.getBook().getBookName() : null)
                .book_image_url(r.getBook() != null ? r.getBook().getBookImageUrl() : null)
                .response_start_page(r.getResponseStartPage())
                .response_end_page(r.getResponseEndPage())
                .unrecognized_response_count(r.getUnrecognizedResponseCount())
                .created_at(r.getCreatedAt())
                .updated_at(r.getUpdatedAt())
                .build();
    }

    public static List<StudentResponseDto> toDtoList(List<StudentResponse> list) {
        return list.stream().map(StudentResponseMapper::toDto).toList();
    }


}

