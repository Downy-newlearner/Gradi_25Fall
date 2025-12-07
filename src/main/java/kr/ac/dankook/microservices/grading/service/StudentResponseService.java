package kr.ac.dankook.microservices.grading.service;

import kr.ac.dankook.microservices.grading.dto.AcademyUserWorkbookDto;
import kr.ac.dankook.microservices.grading.dto.BookSolvedDto;
import kr.ac.dankook.microservices.grading.dto.StudentResponseDto;

import kr.ac.dankook.microservices.grading.entity.*;
import kr.ac.dankook.microservices.grading.mapper.StudentResponseMapper;
import kr.ac.dankook.microservices.grading.repository.AssessmentRepository;
import kr.ac.dankook.microservices.grading.repository.BookRepository;
import kr.ac.dankook.microservices.grading.repository.ChapterRepository;
import kr.ac.dankook.microservices.grading.repository.StudentResponseRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StudentResponseService {

    private final StudentResponseRepository studentResponseRepository;
    private final AssessmentRepository assessmentRepository;
    private final BookRepository bookRepository;

    // Create
    public StudentResponseDto create(StudentResponseDto dto) {

        Assessment assessment = null;
        Book book = null;

        // assess_id가 null이 아니면 조회, null이면 그냥 null 유지
        if (dto.getAssess_id() != null) {
            assessment = assessmentRepository.findById(dto.getAssess_id())
                    .orElse(null);  // ✨ 핵심: 없으면 null
        }

        // book_id가 null/0이 아니면 조회
        if (dto.getBook_id() != null) {
            book = bookRepository.findBookByBookId(dto.getBook_id())
                    .orElse(null);   // ✨ 마찬가지로 null 허용
        }

        StudentResponse entity = StudentResponseMapper.toEntity(dto, assessment, book);
        StudentResponse saved = studentResponseRepository.save(entity);

        return StudentResponseMapper.toDto(saved);
    }

    // Get all
    public List<StudentResponseDto> getAll() {
        return studentResponseRepository.findAll()
                .stream()
                .map(StudentResponseMapper::toDto)
                .collect(Collectors.toList());
    }

    // Get by ID
    public StudentResponseDto getById(Long id) {
        return studentResponseRepository.findById(id)
                .map(StudentResponseMapper::toDto)
                .orElse(null);
    }

    // Update
    public StudentResponseDto update(Long id, StudentResponseDto dto) {
        StudentResponse entity = studentResponseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("StudentResponse not found"));

        entity.setAcademyUserId(dto.getAcademy_user_id());

        if (dto.getAssess_id() != null) {
            Assessment assessment = assessmentRepository.findById(dto.getAssess_id())
                    .orElseThrow(() -> new IllegalArgumentException("Assessment not found"));
            entity.setAssessment(assessment);
        }

        if (dto.getBook_id() != null) {
            Book book = bookRepository.findBookByBookId(dto.getBook_id())
                    .orElseThrow(() -> new IllegalArgumentException("Book not found"));
            entity.setBook(book);
        }

        StudentResponse updated = studentResponseRepository.save(entity);
        return StudentResponseMapper.toDto(updated);
    }

    // Delete
    public void delete(Long id) {
        studentResponseRepository.deleteById(id);
    }


    public List<AcademyUserWorkbookDto> getWorkbookData(List<Long> academyUserIds) {

        // 1. academyUserId 목록으로 StudentResponse 조회
        List<StudentResponse> responses =
                studentResponseRepository.findByAcademyUserIdIn(academyUserIds);

        // academyUserId 단위로 그룹화
        Map<Long, List<StudentResponse>> byUser =
                responses.stream().collect(Collectors.groupingBy(StudentResponse::getAcademyUserId));

        List<AcademyUserWorkbookDto> result = new ArrayList<>();

        for (Long userId : byUser.keySet()) {
            List<StudentResponse> userResponses = byUser.get(userId);

            // 해당 유저의 응답을 book별로 그룹화 (book이 null이면 key = 0L)
            Map<Long, List<StudentResponse>> byBook = userResponses.stream()
                    .collect(Collectors.groupingBy(r -> r.getBook() != null ? r.getBook().getBookId() : 0L));

            List<BookSolvedDto> bookSolvedList = new ArrayList<>();

            for (Long bookId : byBook.keySet()) {
                List<StudentResponse> bookResponses = byBook.get(bookId);

                // book 객체 (null 가능)
                Book book = bookResponses.get(0).getBook();

                // 총 해결 페이지 계산 (start/end가 0이면 0으로 처리)
                int totalSolvedPages = bookResponses.stream()
                        .mapToInt(r -> {
                            int start = r.getResponseStartPage();
                            int end = r.getResponseEndPage();
                            return end >= start ? end - start + 1 : 0; // 안전하게 처리
                        })
                        .sum();

                LocalDateTime latestUpdatedAt = bookResponses.stream()
                        .map(r -> r.getUpdatedAt() != null ? r.getUpdatedAt() : r.getCreatedAt())
                        .max(LocalDateTime::compareTo)
                        .orElse(null);


                // BookSolvedDto 생성 (int 필드 null 안전 처리)
                bookSolvedList.add(
                        new BookSolvedDto(
                                book != null ? book.getBookId() : null,
                                book != null ? book.getBookName() : null,
                                book != null ? book.getBookPage() : 0,
                                book != null ? book.getBookSemester() : null,
                                book != null ? book.getBookImageUrl() : null,
                                totalSolvedPages,
                                latestUpdatedAt
                        )
                );
            }

            // AcademyUserWorkbookDto 생성
            result.add(new AcademyUserWorkbookDto(userId, bookSolvedList));
        }

        return result;
    }

    public List<AcademyUserWorkbookDto> getWorkbookDataInRange(
            List<Long> academyUserIds,
            LocalDateTime startDate,
            LocalDateTime endDate
    ) {

        // 1. 날짜 구간 + academyUserId 조건으로 StudentResponse 조회
        List<StudentResponse> responses =
                studentResponseRepository.findByAcademyUserIdInAndCreatedAtBetween(
                        academyUserIds, startDate, endDate
                );

        // 유저 단위로 그룹화
        Map<Long, List<StudentResponse>> byUser =
                responses.stream().collect(Collectors.groupingBy(StudentResponse::getAcademyUserId));

        List<AcademyUserWorkbookDto> result = new ArrayList<>();

        for (Long userId : byUser.keySet()) {
            List<StudentResponse> userResponses = byUser.get(userId);

            // book 기준 그룹화 (null이면 0L)
            Map<Long, List<StudentResponse>> byBook = userResponses.stream()
                    .collect(Collectors.groupingBy(r -> r.getBook() != null ? r.getBook().getBookId() : 0L));

            List<BookSolvedDto> bookSolvedList = new ArrayList<>();

            for (Long bookId : byBook.keySet()) {
                List<StudentResponse> bookResponses = byBook.get(bookId);

                Book book = bookResponses.get(0).getBook();

                /*
                 * 날짜 구간 내 "실제로 푼 유니크 페이지 수" 계산
                 * 0~0은 실제 풀이가 아니므로 무시
                 */
                Set<Integer> solvedPages = new HashSet<>();

                for (StudentResponse r : bookResponses) {

                    int start = r.getResponseStartPage();
                    int end = r.getResponseEndPage();

                    // ❗ 0~0 응답은 무시해야 함
                    if (start == 0 && end == 0) {
                        continue;
                    }

                    // 정상 범위만 처리
                    if (end >= start) {
                        for (int p = start; p <= end; p++) {
                            solvedPages.add(p);
                        }
                    }
                }

                int totalSolvedPages = solvedPages.size();

                // 최신 업데이트 시간
                LocalDateTime latestUpdatedAt = bookResponses.stream()
                        .map(r -> r.getUpdatedAt() != null ? r.getUpdatedAt() : r.getCreatedAt())
                        .max(LocalDateTime::compareTo)
                        .orElse(null);

                bookSolvedList.add(
                        new BookSolvedDto(
                                book != null ? book.getBookId() : null,
                                book != null ? book.getBookName() : null,
                                book != null ? book.getBookPage() : 0,
                                book != null ? book.getBookSemester() : null,
                                book != null ? book.getBookImageUrl() : null,
                                totalSolvedPages,
                                latestUpdatedAt
                        )
                );
            }

            result.add(new AcademyUserWorkbookDto(userId, bookSolvedList));
        }

        return result;
    }





    public List<StudentResponseDto> getResponsesByAcademyUserIds(List<Long> academyUserIds) {
        List<StudentResponse> responses =
                studentResponseRepository.findByAcademyUserIdIn(academyUserIds);

        return responses.stream()
                .map(StudentResponseMapper::toDto)
                .collect(Collectors.toList());
    }



    public List<StudentResponseDto> getCreatedAtByAcademyUserIds(List<Long> academyUserIds) {
        List<StudentResponse> responses =
                studentResponseRepository.findByAcademyUserIdIn(academyUserIds);

        return responses.stream()
                .map(r -> new StudentResponseDto(r.getStudentResponseId(), r.getCreatedAt()))
                .collect(Collectors.toList());
    }

}
