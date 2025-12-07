package kr.ac.dankook.microservices.grading.service;

import kr.ac.dankook.microservices.grading.dto.GradingHistoryDto;
import kr.ac.dankook.microservices.grading.dto.StudentResponseDto;
import kr.ac.dankook.microservices.grading.entity.GradingHistory;
import kr.ac.dankook.microservices.grading.entity.StudentResponse;
import kr.ac.dankook.microservices.grading.mapper.GradingHistoryMapper;
import kr.ac.dankook.microservices.grading.mapper.StudentResponseMapper;
import kr.ac.dankook.microservices.grading.repository.GradingHistoryRepository;
import kr.ac.dankook.microservices.grading.repository.StudentResponseRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class GradingHistoryService {
    private final GradingHistoryRepository gradingHistoryRepository;
    private final StudentResponseRepository studentResponseRepository;

    public List<GradingHistoryDto> getAll() {
        return gradingHistoryRepository.findAll().stream()
                .map(GradingHistoryMapper::toDto)
                .collect(Collectors.toList());
    }

    public List<GradingHistory> findByGraderId(Long graderId) {
        return gradingHistoryRepository.findByGraderId(graderId);
    }


    public List<StudentResponseDto> convertToStudentResponseDtos(List<GradingHistory> histories) {
        return histories.stream()
                .map(h -> StudentResponseMapper.toDto(h.getStudentResponse()))
                .toList();
    }


    public double getTotalScoreSum(Long academyUserId, Long studentResponseId) {
        Double sum = gradingHistoryRepository.getTotalScoreSum(academyUserId, studentResponseId);
        return sum != null ? sum : 0.0;
    }


    public long getDaysSinceStartOfYear() {
        LocalDate startOfYear = LocalDate.of(LocalDate.now().getYear(), 1, 1);
        return ChronoUnit.DAYS.between(startOfYear, LocalDate.now()) + 1; // 오늘 포함하려면 +1
    }

    public double getTotalScoreByAcademyUser(Long academyUserId) {
        Double sum = gradingHistoryRepository.getTotalScoreByAcademyUserId(academyUserId);
        return sum != null ? sum : 0.0;
    }



    public GradingHistoryDto getById(Long id) {
        return gradingHistoryRepository.findById(id)
                .map(GradingHistoryMapper::toDto)
                .orElse(null);
    }

    public GradingHistoryDto create(GradingHistoryDto dto) {
        StudentResponse studentResponse = studentResponseRepository.findById(dto.getStudent_response_id())
                .orElseThrow(() -> new IllegalArgumentException("Invalid studentResponseId: " + dto.getStudent_response_id()));

        GradingHistory entity = GradingHistoryMapper.toEntity(dto, studentResponse);
        return GradingHistoryMapper.toDto(gradingHistoryRepository.save(entity));
    }

    public GradingHistoryDto update(Long id, GradingHistoryDto dto) {
        return gradingHistoryRepository.findById(id).map(entity -> {
            StudentResponse studentResponse = studentResponseRepository.findById(dto.getStudent_response_id())
                    .orElseThrow(() -> new IllegalArgumentException("Invalid studentResponseId: " + dto.getStudent_response_id()));

            entity.setStudentResponse(studentResponse);
            entity.setTotalScore(dto.getTotal_score());
            entity.setGradeAt(dto.getGrade_at());
            entity.setGraderId(dto.getGrader_id());

            return GradingHistoryMapper.toDto(gradingHistoryRepository.save(entity));
        }).orElse(null);
    }

    public void delete(Long id) {
        gradingHistoryRepository.deleteById(id);
    }
}
