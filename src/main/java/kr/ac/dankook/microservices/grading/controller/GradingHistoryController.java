package kr.ac.dankook.microservices.grading.controller;

import kr.ac.dankook.microservices.grading.dto.GradingHistoryDto;
import kr.ac.dankook.microservices.grading.entity.GradingHistory;
import kr.ac.dankook.microservices.grading.service.GradingHistoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/grading-histories")
@RequiredArgsConstructor
public class GradingHistoryController {

    private final GradingHistoryService gradingHistoryService;

    @GetMapping
    public ResponseEntity<List<GradingHistoryDto>> getAll() {
        return ResponseEntity.ok(gradingHistoryService.getAll());
    }

    @GetMapping("/total-score")
    public double getTotalScore(
            @RequestParam Long academyUserId,
            @RequestParam Long studentResponseId
    ) {
        return gradingHistoryService.getTotalScoreSum(academyUserId, studentResponseId);
    }

    @GetMapping("/summary")
    public Map<String, Object> getSummary(@RequestParam Long academyUserId) {
        long daysSinceStartOfYear = gradingHistoryService.getDaysSinceStartOfYear();
        double totalScore = gradingHistoryService.getTotalScoreByAcademyUser(academyUserId);

        return Map.of(
                "days_since_start_of_year", daysSinceStartOfYear,
                "total_score", totalScore
        );
    }
    @GetMapping("/list")
    public List<GradingHistory> getGradingHistoriesAndStudentResponses(
            @RequestParam Long graderId
    ) {
        return gradingHistoryService.findByGraderId(graderId);
    }



    @GetMapping("/{id}")
    public ResponseEntity<GradingHistoryDto> getById(@PathVariable Long id) {
        GradingHistoryDto dto = gradingHistoryService.getById(id);
        return dto != null ? ResponseEntity.ok(dto) : ResponseEntity.notFound().build();
    }

    @PostMapping
    public ResponseEntity<GradingHistoryDto> create(@RequestBody GradingHistoryDto dto) {
        return ResponseEntity.ok(gradingHistoryService.create(dto));
    }

    @PutMapping("/{id}")
    public ResponseEntity<GradingHistoryDto> update(@PathVariable Long id, @RequestBody GradingHistoryDto dto) {
        GradingHistoryDto updated = gradingHistoryService.update(id, dto);
        return updated != null ? ResponseEntity.ok(updated) : ResponseEntity.notFound().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        gradingHistoryService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
