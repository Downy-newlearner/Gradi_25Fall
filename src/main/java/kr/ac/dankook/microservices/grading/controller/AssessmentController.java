package kr.ac.dankook.microservices.grading.controller;

import kr.ac.dankook.microservices.grading.dto.AssessmentDto;
import kr.ac.dankook.microservices.grading.entity.Assessment;
import kr.ac.dankook.microservices.grading.service.AssessmentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/assessments")
@RequiredArgsConstructor
public class AssessmentController {
    private final AssessmentService service;

    @GetMapping
    public ResponseEntity<List<AssessmentDto>> getAll() {
        return ResponseEntity.ok(service.getAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<AssessmentDto> getById(@PathVariable Long id) {
        AssessmentDto dto = service.getById(id);
        return dto != null ? ResponseEntity.ok(dto) : ResponseEntity.notFound().build();
    }

    @PostMapping
    public ResponseEntity<AssessmentDto> create(@RequestBody AssessmentDto dto) {
        return ResponseEntity.ok(service.create(dto));
    }

    @PutMapping("/{id}")
    public ResponseEntity<AssessmentDto> update(@PathVariable Long id, @RequestBody AssessmentDto dto) {
        AssessmentDto updated = service.update(id, dto);
        return updated != null ? ResponseEntity.ok(updated) : ResponseEntity.notFound().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/assignee/{assigneeId}/{dateTime}")
    public ResponseEntity<List<Assessment>> getAssessments(
            @PathVariable Long assigneeId,
            @PathVariable LocalDateTime dateTime
    ) {
        List<Assessment> list = service.getAssessmentsByAssignee(assigneeId, dateTime);
        return ResponseEntity.ok(list);
    }



}
