package kr.ac.dankook.microservices.grading.service;

import kr.ac.dankook.microservices.grading.dto.QuestionDto;
import kr.ac.dankook.microservices.grading.entity.Question;
import kr.ac.dankook.microservices.grading.mapper.QuestionMapper;
import kr.ac.dankook.microservices.grading.repository.QuestionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class QuestionService {

    private final QuestionRepository questionRepository;
    private final QuestionMapper questionMapper;

    public List<QuestionDto> getAllQuestions() {
        return questionRepository.findAll().stream()
                .map(QuestionMapper::toDto)
                .collect(Collectors.toList());
    }

    public QuestionDto getQuestionById(Long id) {
        return questionRepository.findById(id)
                .map(QuestionMapper::toDto)
                .orElse(null);
    }

    public QuestionDto createQuestion(QuestionDto dto) {
        Question question = QuestionMapper.toEntity(dto);
        Question saved = questionRepository.save(question);
        return QuestionMapper.toDto(saved);
    }


    public QuestionDto updateQuestion(Long id, QuestionDto dto) {
        return questionRepository.findById(id)
                .map(existing -> {
                    Question updated = questionMapper.updateEntityFromDto(existing, dto);
                    Question saved = questionRepository.save(updated);
                    return QuestionMapper.toDto(saved);
                })
                .orElse(null);
    }


    public void deleteQuestion(Long id) {
        questionRepository.deleteById(id);
    }

    public List<QuestionDto> createQuestions(List<QuestionDto> dtos) {
        return dtos.stream()
                .map(this::createQuestion)
                .toList();
    }

}
