package kr.ac.dankook.microservices.grading.mapper;


import kr.ac.dankook.microservices.grading.dto.QuestionDto;
import kr.ac.dankook.microservices.grading.entity.Question;
import org.springframework.stereotype.Component;

@Component
public class QuestionMapper {

    public static QuestionDto toDto(Question question) {
        if (question == null) return null;
        QuestionDto dto = new QuestionDto();
        dto.setQuestion_id(question.getQuestionId());
        dto.setChapter_id(question.getChapterId());
        dto.setPage(question.getPage());
        dto.setPoint(question.getPoint());
        dto.setQuestion_number(question.getQuestionNumber());
        dto.setSub_question_number(question.getSubQuestionNumber());
        dto.setAnswer(question.getAnswer());
        dto.setAnswer_count(question.getAnswerCount());
        return dto;
    }

    public static Question toEntity(QuestionDto dto) {
        if (dto == null) return null;
        Question question = new Question();
        question.setQuestionId(dto.getQuestion_id());
        question.setChapterId(dto.getChapter_id());
        question.setPage(dto.getPage());
        question.setPoint(dto.getPoint());
        question.setQuestionNumber(dto.getQuestion_number());
        question.setSubQuestionNumber(dto.getSub_question_number());
        question.setAnswer(dto.getAnswer());
        question.setAnswerCount(dto.getAnswer_count());
        return question;
    }

    // ✅ update용 메서드 추가
    public Question updateEntityFromDto(Question entity, QuestionDto dto) {
        if (dto == null) return entity;

        entity.setChapterId(dto.getChapter_id());
        entity.setPage(dto.getPage());
        entity.setPoint(dto.getPoint());
        entity.setQuestionNumber(dto.getQuestion_number());
        entity.setSubQuestionNumber(dto.getSub_question_number());
        entity.setAnswer(dto.getAnswer());
        entity.setAnswerCount(dto.getAnswer_count());

        return entity;
    }

}
