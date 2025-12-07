package kr.ac.dankook.microservices.academy.service;


import kr.ac.dankook.microservices.academy.dto.ClassEntityDto;
import kr.ac.dankook.microservices.academy.entity.AcademyUser;
import kr.ac.dankook.microservices.academy.entity.ClassEntity;
import kr.ac.dankook.microservices.academy.mapper.ClassEntityMapper;
import kr.ac.dankook.microservices.academy.repository.AcademyUserRepository;
import kr.ac.dankook.microservices.academy.repository.ClassEntityRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class ClassEntityService {

    @Autowired
    private ClassEntityRepository classEntityRepository;

    @Autowired
    private AcademyUserRepository academyUserRepository;


    public ClassEntity create(ClassEntityDto classEntityDto) {
        ClassEntity classEntity = ClassEntityMapper.toEntity(classEntityDto);
        return classEntityRepository.save(classEntity);
    }

    public List<ClassEntity> findAll() {
        return classEntityRepository.findAll();
    }

    public ClassEntity findById(Long id) {
        return classEntityRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("ClassEntity not found"));
    }

    public ClassEntity update(ClassEntityDto updatedDto) {
        ClassEntity classEntity = ClassEntityMapper.toEntity(updatedDto);
        return classEntityRepository.save(classEntity);
    }

    public void delete(Long id) {
        classEntityRepository.deleteById(id);
    }

    public String getClassNameByAcademyUserId(Long academyUserId) {

        // academy_user 조회
        AcademyUser user = academyUserRepository.findById(academyUserId)
                .orElseThrow(() -> new RuntimeException("AcademyUser not found: " + academyUserId));

        // academy_user 안에 classId 있음
        Long classId = user.getClassId();
        if (classId == null) {
            throw new RuntimeException("academy_user has no classId: " + academyUserId);
        }

        // class 조회
        ClassEntity classEntity = classEntityRepository.findById(classId)
                .orElseThrow(() -> new RuntimeException("Class not found: " + classId));

        return classEntity.getClassName();
    }
}
