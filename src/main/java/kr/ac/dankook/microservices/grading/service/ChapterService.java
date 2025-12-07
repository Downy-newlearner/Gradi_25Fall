package kr.ac.dankook.microservices.grading.service;

import kr.ac.dankook.microservices.grading.dto.ChapterDto;
import kr.ac.dankook.microservices.grading.dto.QuestionDto;
import kr.ac.dankook.microservices.grading.entity.Book;
import kr.ac.dankook.microservices.grading.entity.Chapter;
import kr.ac.dankook.microservices.grading.entity.StudentAnswer;
import kr.ac.dankook.microservices.grading.entity.StudentResponse;
import kr.ac.dankook.microservices.grading.mapper.ChapterMapper;
import kr.ac.dankook.microservices.grading.mapper.QuestionMapper;
import kr.ac.dankook.microservices.grading.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ChapterService {

    private final ChapterRepository chapterRepository;
    private final BookRepository bookRepository;
    private final QuestionRepository questionRepository;
    private final StudentResponseRepository studentResponseRepository;
    private final StudentAnswerRepository studentAnswerRepository;

    // -----------------------------
    // 전체 조회
    // -----------------------------
    public List<ChapterDto> getAll() {
        return chapterRepository.findAll()
                .stream()
                .map(ch -> ChapterMapper.toDto(ch, 0L))
                .collect(Collectors.toList());
    }

    // -----------------------------
    // 단일 조회
    // -----------------------------
    public ChapterDto getById(Long id) {
        return chapterRepository.findById(id)
                .map(ch -> ChapterMapper.toDto(ch, 0L))
                .orElse(null);
    }

    // -----------------------------
    // 생성
    // -----------------------------
    public ChapterDto create(ChapterDto dto) {
        Book book = bookRepository.findById(dto.getBook_id())
                .orElseThrow(() -> new IllegalArgumentException("Book not found: " + dto.getBook_id()));

        Chapter chapter = ChapterMapper.toEntity(dto, book);

        Chapter saved = chapterRepository.save(chapter);

        return ChapterMapper.toDto(saved, 0L);
    }

    // -----------------------------
    // 수정
    // -----------------------------
    public ChapterDto update(Long id, ChapterDto dto) {

        return chapterRepository.findById(id)
                .map(entity -> {

                    Book book = bookRepository.findById(dto.getBook_id())
                            .orElseThrow(() -> new IllegalArgumentException("Book not found: " + dto.getBook_id()));

                    ChapterMapper.updateEntityFromDto(dto, entity, book);

                    Chapter saved = chapterRepository.save(entity);
                    return ChapterMapper.toDto(saved, 0L);
                })
                .orElse(null);
    }

    // -----------------------------
    // 삭제
    // -----------------------------
    public void delete(Long id) {
        chapterRepository.deleteById(id);
    }

    // -----------------------------
    // bookId 기준 챕터 전체 조회
    // -----------------------------
    public List<ChapterDto> getChaptersByBookId(Long bookId) {

        List<Chapter> chapters = chapterRepository.findByBookBookId(bookId);

        return chapters.stream()
                .map(ch -> ChapterMapper.toDto(ch, 0L))
                .collect(Collectors.toList());
    }

    // -----------------------------
    // 특정 유저가 푼 문제 개수와 함께 챕터 목록 조회
    // -----------------------------
    public List<ChapterDto> getChaptersByBookIdAndUser(Long bookId, Long academyUserId) {

        // 1. bookId 기준 챕터 전체 조회
        List<Chapter> chapters = chapterRepository.findByBookBookId(bookId);

        // 2. 학생의 모든 student_response 조회
        List<StudentResponse> responses =
                studentResponseRepository.findByAcademyUserIdAndBook_BookId(academyUserId, bookId);

        List<Long> responseIds = responses.stream()
                .map(StudentResponse::getStudentResponseId)
                .toList();

        // 3. student_answer 전체 조회
        List<StudentAnswer> answers =
                studentAnswerRepository.findByStudentResponseIdIn(responseIds);

        // 4. 문제별로 묶기 → chapterId + questionNumber + subQuestionNumber 기준
        Map<String, List<StudentAnswer>> grouped =
                answers.stream().collect(Collectors.groupingBy(a ->
                        a.getChapterId() + "-" + a.getQuestionNumber() + "-" + a.getSubQuestionNumber()
                ));

        // 5. 각 문제에서 대표 답안 선택
        Set<String> solvedProblems = new HashSet<>();

        for (Map.Entry<String, List<StudentAnswer>> entry : grouped.entrySet()) {
            List<StudentAnswer> list = entry.getValue();

            // 1) 정답이 있는 경우 우선 선택
            Optional<StudentAnswer> correctOne = list.stream()
                    .filter(StudentAnswer::isCorrect)
                    .findFirst();

            if (correctOne.isPresent()) {
                solvedProblems.add(entry.getKey());
                continue;
            }

            // 2) 모두 틀렸다면 student_response_id 가장 큰 것 사용
            StudentAnswer latestWrong = list.stream()
                    .max(Comparator.comparing(StudentAnswer::getStudentResponseId))
                    .get();

            solvedProblems.add(entry.getKey());
        }

        // chapterId별 solved 개수 집계
        Map<Long, Long> chapterSolvedCount = new HashMap<>();

        for (String key : solvedProblems) {
            Long chapterId = Long.parseLong(key.split("-")[0]);
            chapterSolvedCount.put(
                    chapterId,
                    chapterSolvedCount.getOrDefault(chapterId, 0L) + 1
            );
        }

        // DTO 변환
        return chapters.stream()
                .map(ch -> ChapterMapper.toDto(
                        ch,
                        chapterSolvedCount.getOrDefault(ch.getChapterId(), 0L)
                ))
                .collect(Collectors.toList());
    }



    public List<QuestionDto> getQuestionsByChapterId(Long chapterId) {
            return questionRepository.findByChapterId(chapterId)
                    .stream()
                    .map(QuestionMapper::toDto)     // ← 변경됨
                    .collect(Collectors.toList());
        }

}


