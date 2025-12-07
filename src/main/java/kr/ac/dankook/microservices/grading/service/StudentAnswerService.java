package kr.ac.dankook.microservices.grading.service;


import com.fasterxml.jackson.databind.ObjectMapper;
import kr.ac.dankook.microservices.common.dto.AnswerExplanationMessage;
import kr.ac.dankook.microservices.grading.dto.StudentAnswerDto;
import kr.ac.dankook.microservices.grading.entity.StudentResponse;
import kr.ac.dankook.microservices.grading.dto.StudentAnswerUpdateDto;
import kr.ac.dankook.microservices.grading.entity.Question;
import kr.ac.dankook.microservices.grading.entity.StudentAnswer;
import kr.ac.dankook.microservices.grading.mapper.StudentAnswerMapper;
import kr.ac.dankook.microservices.grading.mapper.StudentResponseMapper;
import kr.ac.dankook.microservices.grading.repository.QuestionRepository;
import kr.ac.dankook.microservices.grading.repository.StudentAnswerRepository;
import kr.ac.dankook.microservices.grading.repository.StudentResponseRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StudentAnswerService {

    private final ObjectMapper objectMapper;
    private final StudentAnswerRepository studentAnswerRepository;
    private final QuestionRepository questionRepository;
    private final StudentResponseRepository studentResponseRepository;
    private final RedisTemplate<String, String> redisTemplate;

    public StudentAnswerDto create(StudentAnswerDto dto) {
        StudentAnswer entity = StudentAnswerMapper.toEntity(dto);
        StudentAnswer saved = studentAnswerRepository.save(entity);
        return StudentAnswerMapper.toDto(saved);
    }

    @Transactional
    public StudentAnswer updateStudentAnswer(StudentAnswerUpdateDto dto) {

        // 1. 학생 답안 조회
        StudentAnswer studentAnswer = studentAnswerRepository.findById(dto.getStudent_answer_id())
                .orElseThrow(() -> new IllegalArgumentException("Invalid student_answer_id"));

        // 2. Question 테이블에서 정답 조회
        Question question = questionRepository
                .findByChapterIdAndQuestionNumberAndSubQuestionNumber(
                        dto.getChapter_id(),
                        dto.getQuestion_number(),
                        dto.getSub_question_number()
                )
                .orElseThrow(() -> new IllegalArgumentException("Question not found"));

        String correctAnswer = question.getAnswer().trim().toLowerCase();
        String submittedAnswer = dto.getAnswer().trim().toLowerCase();

        boolean isCorrect = submittedAnswer.equals(correctAnswer);

        // 3. 학생 답안 업데이트
        studentAnswer.setAnswer(dto.getAnswer());
        studentAnswer.setCorrect(isCorrect);
        studentAnswer.setScore(isCorrect ? 1 : 0);

        // 4. 저장
        return studentAnswerRepository.save(studentAnswer);
    }








    public void delete(Long id) {
        studentAnswerRepository.deleteById(id);
    }

    public List<StudentAnswer> getAll() {
        return studentAnswerRepository.findAll();
    }


    public List<StudentAnswerDto> getAnswersByStudentResponseId(Long studentResponseId) {
        List<StudentAnswer> answers = studentAnswerRepository.findByStudentResponseId(studentResponseId);
        return StudentAnswerMapper.toDtoList(answers);
    }

    /**
     * Redis에서 Explanation 조회
     */
    public AnswerExplanationMessage getExplanation(
            Long studentResponseId,
            int academyUserId,
            int questionNumber,
            int subQuestionNumber
    ) {
        try {
            // Redis key 생성
            String key = String.format(
                    "answer-explanation:%d:%d:%d:%d",
                    studentResponseId,
                    academyUserId,
                    questionNumber,
                    subQuestionNumber
            );

            String value = redisTemplate.opsForValue().get(key);

            if (value == null) {
                return null; // Controller에서 처리하도록 null 반환
            }

            return objectMapper.readValue(value, AnswerExplanationMessage.class);

        } catch (Exception e) {
            throw new RuntimeException("Failed to load explanation from Redis", e);
        }
    }

    public List<StudentAnswerDto> getAnswersByAcademyUserAndChapter(Long academyUserId, Long chapterId) {

        // 1️⃣ academy_user_id로 student_response_id 리스트 조회
        List<Long> responseIds = studentResponseRepository
                .findByAcademyUserId(academyUserId)
                .stream()
                .map(StudentResponse::getStudentResponseId)
                .toList();

        if (responseIds.isEmpty()) return List.of();

        // 2️⃣ student_response_id + chapter_id로 answers 조회
        List<StudentAnswer> answers =
                studentAnswerRepository.findByStudentResponseIdInAndChapterId(responseIds, chapterId);

        // 3️⃣ 중복 제거 규칙 적용:
        //    규칙: (1) 맞은 것이 있으면 맞은 것 선택
        //         (2) 모두 틀리면 student_response_id 가장 큰(최신) 답안 선택
        List<StudentAnswer> distinctAnswers = answers.stream()
                .collect(Collectors.groupingBy(
                        a -> a.getQuestionNumber() + "-" + a.getSubQuestionNumber()
                ))
                .values()
                .stream()
                .map(answerList -> {

                    // 3-1. 먼저 맞은 것( isCorrect = true ) 찾기
                    Optional<StudentAnswer> correctOne = answerList.stream()
                            .filter(StudentAnswer::isCorrect)
                            .findFirst();

                    if (correctOne.isPresent()) {
                        return correctOne.get(); // 맞은 게 있으면 그거 선택
                    }

                    // 3-2. 모두 틀렸다면 student_response_id 가장 큰(최신 시도) 선택
                    return answerList.stream()
                            .max(Comparator.comparing(StudentAnswer::getStudentResponseId))
                            .orElse(answerList.get(0));

                })
                .toList();

        // 4️⃣ DTO 변환
        return StudentAnswerMapper.toDtoList(distinctAnswers);
    }

    public StudentAnswer getAnswerByResponseAndQuestion(
            Long studentResponseId,
            int questionNumber,
            int subQuestionNumber
    ) {
        return studentAnswerRepository
                .findByStudentResponseIdAndQuestionNumberAndSubQuestionNumber(
                        studentResponseId,
                        questionNumber,
                        subQuestionNumber
                )
                .orElseThrow(() ->
                        new IllegalArgumentException("StudentAnswer not found for provided identifiers")
                );
    }

}



