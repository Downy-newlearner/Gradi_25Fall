package kr.ac.dankook.microservices.academy.controller;

import kr.ac.dankook.microservices.academy.dto.StudentDto;
import kr.ac.dankook.microservices.academy.service.StudentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/students")
@RequiredArgsConstructor
public class StudentController {

    private final StudentService studentService;

    /**
     * 학생 등록
     */
    @PostMapping
    public ResponseEntity<StudentDto> createStudent(@RequestBody StudentDto studentDto) {
        StudentDto created = studentService.createStudent(studentDto);
        return ResponseEntity.ok(created);
    }

    /**
     * 특정 학생 조회 (studentId 기준)
     */
    @GetMapping("/{studentId}")
    public ResponseEntity<StudentDto> getStudentById(@PathVariable Long studentId) {
        return studentService.getStudentById(studentId)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    /**
     * 특정 userId로 학생 조회
     */
    @GetMapping("/{userId}")
    public ResponseEntity<StudentDto> getStudentByUserId(@PathVariable Long userId) {
        return studentService.getStudentByUserId(userId)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    /**
     * 전체 학생 목록 조회
     */
    @GetMapping
    public ResponseEntity<List<StudentDto>> getAllStudents() {
        List<StudentDto> students = studentService.getAllStudents();
        if (students.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(students);
    }

    /**
     * 학생 정보 수정
     */
    @PutMapping("/{userId}")
    public ResponseEntity<StudentDto> updateStudent(
            @PathVariable Long userId,
            @RequestBody StudentDto studentDto) {

        return studentService.updateStudent(userId, studentDto)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    /**
     * 학생 삭제
     */
    @DeleteMapping("/{userId}")
    public ResponseEntity<Void> deleteStudent(@PathVariable Long userId) {
        return studentService.getStudentByUserId(userId)
                .map(student -> {
                    studentService.deleteStudent(student.getStudent_id());
                    return ResponseEntity.noContent().<Void>build();
                })
                .orElseGet(() -> ResponseEntity.notFound().build());
    }
}
