package kr.ac.dankook.microservices.grading.mapper;

import kr.ac.dankook.microservices.common.dto.StudentAnswerMessage;
import kr.ac.dankook.microservices.grading.dto.StudentAnswerDto;
import kr.ac.dankook.microservices.grading.entity.StudentAnswer;
import java.util.List;
import java.util.stream.Collectors;

public class StudentAnswerMapper {

    public static StudentAnswerDto toDto(StudentAnswer entity) {
        if (entity == null) return null;
        return StudentAnswerDto.builder()
                .student_answer_id(entity.getStudentAnswerId())
                .student_response_id(entity.getStudentResponseId())
                .chapter_id(entity.getChapterId())
                .page(entity.getPage())
                .question_number(entity.getQuestionNumber())
                .sub_question_number(entity.getSubQuestionNumber())
                .answer(entity.getAnswer())
                .section_url(entity.getSection_url())
                .is_correct(entity.isCorrect())
                .score(entity.getScore())
                .build();
    }

    public static StudentAnswer toEntity(StudentAnswerDto dto) {
        if (dto == null) return null;
        return StudentAnswer.builder()
                .studentAnswerId(dto.getStudent_answer_id())
                .page(dto.getPage())
                .chapterId(dto.getChapter_id())
                .studentResponseId(dto.getStudent_response_id())
                .questionNumber(dto.getQuestion_number())
                .subQuestionNumber(dto.getSub_question_number())
                .answer(dto.getAnswer())
                .section_url(dto.getSection_url())
                .isCorrect(dto.getIs_correct())
                .score(dto.getScore())
                .build();
    }

    public static List<StudentAnswer> toEntities(StudentAnswerMessage dto) {

        return dto.getSections().stream().map(section -> {
            StudentAnswer entity = new StudentAnswer();
            entity.setStudentResponseId(dto.getStudentResponseId());
            entity.setPage(dto.getPage());
            entity.setChapterId(dto.getChapterId());
            entity.setQuestionNumber(section.getQuestionNumber());
            entity.setSubQuestionNumber(section.getSubQuestionNumber());
            entity.setAnswer(section.getAnswer());
            entity.setCorrect(section.isCorrect());
            entity.setScore(section.isCorrect() ? 1 : 0);  // 점수 규칙에 맞게 수정 가능



            return entity;
        }).collect(Collectors.toList());
    }

    public static List<StudentAnswerDto> toDtoList(List<StudentAnswer> entities) {
        return entities.stream()
                .map(a -> StudentAnswerDto.builder()
                        .student_answer_id(a.getStudentAnswerId())
                        .student_response_id(a.getStudentResponseId())
                        .chapter_id(a.getChapterId())   // ⭐ 추가
                        .page(a.getPage())
                        .question_number(a.getQuestionNumber())
                        .sub_question_number(a.getSubQuestionNumber())
                        .answer(a.getAnswer())
                        .section_url(a.getSection_url())
                        .is_correct(a.isCorrect())
                        .score(a.getScore())
                        .build()
                )
                .toList();
    }




}
