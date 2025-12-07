package kr.ac.dankook.microservices.grading.controller;

import kr.ac.dankook.microservices.grading.dto.AcademyUserWorkbookDto;
import kr.ac.dankook.microservices.grading.dto.StudentResponseDto;
import kr.ac.dankook.microservices.grading.service.StudentResponseService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/student-responses")
@RequiredArgsConstructor
public class StudentResponseController {

    private final StudentResponseService studentResponseService;

    @GetMapping
    public ResponseEntity<List<StudentResponseDto>> getAll() {
        return ResponseEntity.ok(studentResponseService.getAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<StudentResponseDto> getById(@PathVariable Long id) {
        StudentResponseDto dto = studentResponseService.getById(id);
        return dto != null ? ResponseEntity.ok(dto) : ResponseEntity.notFound().build();
    }

    @PostMapping
    public ResponseEntity<StudentResponseDto> create(@RequestBody StudentResponseDto dto) {
        return ResponseEntity.ok(studentResponseService.create(dto));
    }

    @PutMapping("/{id}")
    public ResponseEntity<StudentResponseDto> update(@PathVariable Long id, @RequestBody StudentResponseDto dto) {
        StudentResponseDto updated = studentResponseService.update(id, dto);
        return updated != null ? ResponseEntity.ok(updated) : ResponseEntity.notFound().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        studentResponseService.delete(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/workbook")
    public ResponseEntity<List<AcademyUserWorkbookDto>> getWorkbookData(
            @RequestParam("academyUserIds") List<Long> academyUserIds
    ) {
        return ResponseEntity.ok(studentResponseService.getWorkbookData(academyUserIds));
    }

    @GetMapping("/workbook/range")
    public ResponseEntity<List<AcademyUserWorkbookDto>> getWorkbookSolvedInRange(
            @RequestParam("academyUserIds") List<Long> academyUserIds,
            @RequestParam("startDate") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam("endDate") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate
    ) {
        return ResponseEntity.ok(studentResponseService.getWorkbookDataInRange(academyUserIds, startDate, endDate));
    }



    @GetMapping("/histories")
    public ResponseEntity<List<StudentResponseDto>> getResponsesByAcademyUserIds(
            @RequestParam List<Long> academyUserIds
    ) {
        return ResponseEntity.ok(studentResponseService.getResponsesByAcademyUserIds(academyUserIds));
    }

    @GetMapping("/createdAt")
    public ResponseEntity<List<StudentResponseDto>> getCreatedAtByAcademyUserIds(
            @RequestParam List<Long> academyUserIds
    ) {
        return ResponseEntity.ok(studentResponseService.getCreatedAtByAcademyUserIds(academyUserIds));
    }




}
