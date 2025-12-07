package kr.ac.dankook.microservices.grading.controller;


import kr.ac.dankook.microservices.common.dto.AnswerExplanationMessage;
import kr.ac.dankook.microservices.grading.dto.BookDto;
import kr.ac.dankook.microservices.grading.dto.ExplanationRequest;
import kr.ac.dankook.microservices.grading.dto.StudentAnswerDto;
import kr.ac.dankook.microservices.grading.dto.StudentAnswerUpdateDto;
import kr.ac.dankook.microservices.grading.entity.StudentAnswer;
import kr.ac.dankook.microservices.grading.service.StudentAnswerService;
import kr.ac.dankook.microservices.grading.service.WebClientService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/student-answers")
@RequiredArgsConstructor
public class StudentAnswerController {

    private final StudentAnswerService studentAnswerService;
    private final WebClientService webClientService;

    @PostMapping
    public ResponseEntity<StudentAnswerDto> create(@RequestBody StudentAnswerDto dto) {
        return ResponseEntity.ok(studentAnswerService.create(dto));
    }

    @GetMapping("/find")
    public ResponseEntity<?> getAnswerByResponseAndQuestion(
            @RequestParam("studentResponseId") Long studentResponseId,
            @RequestParam("questionNumber") int questionNumber,
            @RequestParam("subQuestionNumber") int subQuestionNumber
    ) {
        try {
            StudentAnswer answer = studentAnswerService.getAnswerByResponseAndQuestion(
                    studentResponseId, questionNumber, subQuestionNumber
            );
            return ResponseEntity.ok(answer);

        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        }
    }





    @GetMapping
    public ResponseEntity<List<StudentAnswer>> getAll() {
        return ResponseEntity.ok(studentAnswerService.getAll());
    }

    @GetMapping("/response")
    public List<StudentAnswerDto> getAnswersByStudentResponse(
            @RequestParam("studentResponseId") Long studentResponseId
    ) {
        return studentAnswerService.getAnswersByStudentResponseId(studentResponseId);
    }



    @GetMapping("/get-explanation")
    public ResponseEntity<?> getExplanation(
            @RequestParam("studentResponseId") Long studentResponseId,
            @RequestParam("academyUserId") int academyUserId,
            @RequestParam("questionNumber") int questionNumber,
            @RequestParam("subQuestionNumber") int subQuestionNumber
    ) {
        try {
            AnswerExplanationMessage explanation =
                    studentAnswerService.getExplanation(
                            studentResponseId,
                            academyUserId,
                            questionNumber,
                            subQuestionNumber
                    );

            if (explanation == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body("No explanation found for the given request.");
            }

            return ResponseEntity.ok(explanation);

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Failed to retrieve explanation: " + e.getMessage());
        }
    }


    @PostMapping("/explanation")
    public ResponseEntity<?> postExplanation(@RequestBody ExplanationRequest payload) {
        try {
            String result = webClientService.explanationPost("/api/explanation", payload);
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Failed to send explanation message: " + e.getMessage());
        }
    }


    /**
     * academy_user_id와 chapter_id 기준으로 student_answer 리스트 조회
     * 중복 question/subQuestion은 제거 (is_correct true/false 상관없이)
     */
    @GetMapping("/grass")
    public ResponseEntity<List<StudentAnswerDto>> getAnswersByUserAndChapter(
            @RequestParam("academyUserId") Long academyUserId,
            @RequestParam("chapterId") Long chapterId
    ) {
        List<StudentAnswerDto> answers = studentAnswerService.getAnswersByAcademyUserAndChapter(academyUserId, chapterId);
        return ResponseEntity.ok(answers);
    }

    @PutMapping("/update")
    public ResponseEntity<?> updateStudentAnswer(@RequestBody StudentAnswerUpdateDto dto) {
        try {
            StudentAnswer updated = studentAnswerService.updateStudentAnswer(dto);
            return ResponseEntity.ok(updated);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        }
    }


    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        studentAnswerService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
