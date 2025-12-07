package kr.ac.dankook.microservices.grading.service;

import kr.ac.dankook.microservices.common.dto.GradingEvent;
import kr.ac.dankook.microservices.grading.dto.GradingHistoryDto;
import kr.ac.dankook.microservices.grading.entity.Assessment;
import kr.ac.dankook.microservices.grading.entity.GradingHistory;
import kr.ac.dankook.microservices.grading.repository.AssessmentRepository;
import kr.ac.dankook.microservices.grading.repository.GradingHistoryRepository;
import kr.ac.dankook.microservices.grading.repository.StudentResponseRepository;
import kr.ac.dankook.microservices.grading.mapper.GradingHistoryMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class GradingEndService {

    private final StudentResponseRepository studentResponseRepository;
    private final AssessmentRepository assessmentRepository;
    private final GradingHistoryRepository gradingHistoryRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;

    @Transactional
    public void process(GradingEvent event, String rawMessage) {

        studentResponseRepository.findById(event.getStudentResponseId())
                .ifPresent(sr -> {

                    int startPage = event.getResponseStartPage();
                    int endPage = event.getResponseEndPage();

                    // ======================================================
                    // StudentResponse 업데이트
                    // ======================================================
                    sr.setResponseStartPage(startPage);
                    sr.setResponseEndPage(endPage);

                    // ======================================================
                    // Assessment 업데이트 (범위 기반)
                    // ======================================================
                    List<Assessment> assessments =
                            assessmentRepository.findByAssigneeIdAndBookId(
                                    event.getAcademyUserId(),
                                    event.getBookId()
                            );

                    for (Assessment a : assessments) {
                        boolean contains = a.getAssessStartPage() <= startPage &&
                                a.getAssessEndPage() >= endPage;

                        if (contains) {
                            a.setAssessStatus("Y");
                            assessmentRepository.save(a);

                            // StudentResponse와 연결
                            sr.setAssessment(a);
                            log.info("Assessment {} linked to StudentResponse {}", a.getAssessId(), sr.getStudentResponseId());
                        }
                    }

                    studentResponseRepository.save(sr);

                    // ======================================================
                    // GradingHistory 저장
                    // ======================================================
                    GradingHistoryDto historyDto = GradingHistoryDto.builder()
                            .student_response_id(sr.getStudentResponseId())
                            .total_score(event.getTotalScore())
                            .grade_at(LocalDateTime.now())
                            .grader_id(event.getAcademyUserId())
                            .build();

                    GradingHistory entity = GradingHistoryMapper.toEntity(historyDto, sr);
                    gradingHistoryRepository.save(entity);

                    log.info("GradingHistory saved: {}", entity);

                    // ======================================================
                    // grading-event 재발행
                    // ======================================================
                    kafkaTemplate.send("grading-event", rawMessage);
                });
    }
}
