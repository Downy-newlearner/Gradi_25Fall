//package kr.ac.dankook.microservices.grading.controller;
//
//import kr.ac.dankook.microservices.grading.dto.StudentAcademyCacheDto;
//import kr.ac.dankook.microservices.grading.service.StudentAcademyCacheService;
//import lombok.RequiredArgsConstructor;
//import org.springframework.http.ResponseEntity;
//import org.springframework.web.bind.annotation.*;
//
//import java.util.List;
//
//@RestController
//@RequestMapping("/student-academy-cache")
//@RequiredArgsConstructor
//public class StudentAcademyCacheController {
//    private final StudentAcademyCacheService service;
//
//    @GetMapping
//    public ResponseEntity<List<StudentAcademyCacheDto>> getAll() {
//        return ResponseEntity.ok(service.getAll());
//    }
//
//    @GetMapping("/{id}")
//    public ResponseEntity<StudentAcademyCacheDto> getById(@PathVariable Long id) {
//        StudentAcademyCacheDto dto = service.getById(id);
//        return dto != null ? ResponseEntity.ok(dto) : ResponseEntity.notFound().build();
//    }
//
//    @PostMapping
//    public ResponseEntity<StudentAcademyCacheDto> create(@RequestBody StudentAcademyCacheDto dto) {
//        return ResponseEntity.ok(service.create(dto));
//    }
//
//    @PutMapping("/{id}")
//    public ResponseEntity<StudentAcademyCacheDto> update(@PathVariable Long id, @RequestBody StudentAcademyCacheDto dto) {
//        StudentAcademyCacheDto updated = service.update(id, dto);
//        return updated != null ? ResponseEntity.ok(updated) : ResponseEntity.notFound().build();
//    }
//
//    @DeleteMapping("/{id}")
//    public ResponseEntity<Void> delete(@PathVariable Long id) {
//        service.delete(id);
//        return ResponseEntity.noContent().build();
//    }
//}
