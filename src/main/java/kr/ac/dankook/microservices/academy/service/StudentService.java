package kr.ac.dankook.microservices.academy.service;

import jakarta.transaction.Transactional;
import kr.ac.dankook.microservices.academy.dto.StudentDto;
import kr.ac.dankook.microservices.academy.entity.Student;
import kr.ac.dankook.microservices.academy.mapper.StudentMapper;
import kr.ac.dankook.microservices.academy.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StudentService {

    private final StudentRepository studentRepository;
    private final StudentMapper studentMapper;

    /** 학생 등록 */
    @Transactional
    public StudentDto createStudent(StudentDto studentDto) {
        Student student = studentMapper.toEntity(studentDto);
        Student saved = studentRepository.save(student);
        return studentMapper.toDto(saved);
    }

    /** 학생 단건 조회 */
    public Optional<StudentDto> getStudentById(Long studentId) {
        return studentRepository.findById(studentId)
                .map(studentMapper::toDto);
    }

    /** userId로 조회 */
    public Optional<StudentDto> getStudentByUserId(Long userId) {
        return studentRepository.findByUserId(userId)
                .map(studentMapper::toDto);
    }

    /** 전체 학생 조회 */
    public List<StudentDto> getAllStudents() {
        return studentRepository.findAll()
                .stream()
                .map(studentMapper::toDto)
                .collect(Collectors.toList());
    }

    /** 학생 정보 수정 */
    @Transactional
    public Optional<StudentDto> updateStudent(Long userId, StudentDto studentDto) {
        return studentRepository.findByUserId(userId).map(existing -> {
            existing.setStudentName(studentDto.getStudent_name());
            existing.setStudentGrade(studentDto.getStudent_grade());
            existing.setClassEntityId(studentDto.getClass_entity_id());
            Student updated = studentRepository.save(existing);
            return studentMapper.toDto(updated);
        });
    }

    /** 학생 삭제 */
    @Transactional
    public void deleteStudent(Long studentId) {
        studentRepository.deleteById(studentId);
    }
}
