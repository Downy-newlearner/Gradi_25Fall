package kr.ac.dankook.microservices.grading.controller;

import kr.ac.dankook.microservices.grading.dto.QuestionDto;
import kr.ac.dankook.microservices.grading.service.QuestionService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/question")
@RequiredArgsConstructor
public class QuestionController {

    private final QuestionService questionService;

    @GetMapping
    public List<QuestionDto> getAllQuestions() {
        return questionService.getAllQuestions();
    }

    @GetMapping("/{id}")
    public QuestionDto getQuestion(@PathVariable Long id) {
        return questionService.getQuestionById(id);
    }

    @PostMapping
    public QuestionDto createQuestion(@RequestBody QuestionDto dto) {
        return questionService.createQuestion(dto);
    }

    @PostMapping("/batch")
    public List<QuestionDto> createQuestions(@RequestBody List<QuestionDto> dtos) {
        return questionService.createQuestions(dtos);
    }

    @PutMapping("/{id}")
    public QuestionDto updateQuestion(@PathVariable Long id, @RequestBody QuestionDto dto) {
        return questionService.updateQuestion(id, dto);
    }

    @DeleteMapping("/{id}")
    public void deleteQuestion(@PathVariable Long id) {
        questionService.deleteQuestion(id);
    }
}

