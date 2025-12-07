package kr.ac.dankook.microservices.grading.service;

import kr.ac.dankook.microservices.grading.dto.AssessmentDto;
import kr.ac.dankook.microservices.grading.entity.Assessment;
import kr.ac.dankook.microservices.grading.entity.Book;
import kr.ac.dankook.microservices.grading.entity.Chapter;
import kr.ac.dankook.microservices.grading.mapper.AssessmentMapper;
import kr.ac.dankook.microservices.grading.repository.AssessmentRepository;
import kr.ac.dankook.microservices.grading.repository.BookRepository;
import kr.ac.dankook.microservices.grading.repository.ChapterRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AssessmentService {

    private final AssessmentRepository repository;
    private final BookRepository bookRepository;

    // 전체 조회
    public List<AssessmentDto> getAll() {
        return repository.findAll()
                .stream()
                .map(AssessmentMapper::toDto)
                .collect(Collectors.toList());
    }

    // ID로 조회
    public AssessmentDto getById(Long id) {
        return repository.findById(id)
                .map(AssessmentMapper::toDto)
                .orElse(null);
    }

    // 생성
    public AssessmentDto create(AssessmentDto dto) {
        Book book = null;
        if (dto.getBook_id() != null) {
            book = bookRepository.findById(dto.getBook_id())
                    .orElseThrow(() -> new IllegalArgumentException("Chapter not found"));
        }

        Assessment entity = AssessmentMapper.toEntity(dto, book);
        Assessment saved = repository.save(entity);
        return AssessmentMapper.toDto(saved);
    }

    // 업데이트
    public AssessmentDto update(Long id, AssessmentDto dto) {
        Optional<Book> bookOptional = bookRepository.findBookByBookId(dto.getBook_id());
        Book book = bookOptional.orElseThrow(() -> new IllegalArgumentException("Book not found"));
        return repository.findById(id)
                .map(entity -> {
                    entity.setAssessName(dto.getAssess_name());
                    entity.setAssessType(dto.getAssess_type());
                    entity.setAssessStatus(dto.getAssess_status());
                    entity.setAssessDeadline(dto.getAssess_deadline());
                    entity.setAssessType(dto.getAssess_type());
                    entity.setAssigneeId(dto.getAssignee_id());
                    entity.setAssignerId(dto.getAssigner_id());
                    entity.setBook(book);
                    Assessment updated = repository.save(entity);
                    return AssessmentMapper.toDto(updated);
                }).orElse(null);
    }

    // 삭제
    public void delete(Long id) {
        repository.deleteById(id);
    }

    public List<Assessment> getAssessmentsByAssignee(Long assigneeId, LocalDateTime dateTime) {

        // URL에서 받은 dateTime 기준으로 해당 월 계산
        LocalDate baseDate = dateTime.toLocalDate();

        LocalDateTime startOfMonth = baseDate.withDayOfMonth(1).atStartOfDay();
        LocalDateTime endOfMonth = baseDate.withDayOfMonth(baseDate.lengthOfMonth())
                .atTime(LocalTime.MAX);

        return repository.findAllByAssigneeIdWithDeadlineRange(
                assigneeId,
                startOfMonth,
                endOfMonth
        );
    }

}
