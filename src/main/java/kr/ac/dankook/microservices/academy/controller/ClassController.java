package kr.ac.dankook.microservices.academy.controller;

import kr.ac.dankook.microservices.academy.dto.ClassEntityDto;
import kr.ac.dankook.microservices.academy.entity.ClassEntity;
import kr.ac.dankook.microservices.academy.service.ClassEntityService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;


@Slf4j
@RestController
@RequiredArgsConstructor

@RequestMapping("/class")
public class ClassController {


    @Autowired
    ClassEntityService classEntityService;


    @GetMapping("/academyUser/{academyUserId}")
    public String getClassNameByAcademyUserId(@PathVariable Long academyUserId) {
        return classEntityService.getClassNameByAcademyUserId(academyUserId);
    }


    @PostMapping
    public ClassEntity createClassEntity(@RequestBody ClassEntityDto classEntityDto) {
        return classEntityService.create(classEntityDto);
    }

    @GetMapping
    public List<ClassEntity> getAllAcademies() {
        return classEntityService.findAll();
    }

    @GetMapping("/{id}")
    public ClassEntity getClassEntity(@PathVariable Long id) {
        return classEntityService.findById(id);
    }

    @PutMapping()
    public ClassEntity updateClassEntity(@RequestBody ClassEntityDto classEntityDto) {
        return classEntityService.update(classEntityDto);
    }

    @DeleteMapping("/{id}")
    public void deleteClassEntity(@PathVariable Long id) {
        classEntityService.delete(id);
    }


}
