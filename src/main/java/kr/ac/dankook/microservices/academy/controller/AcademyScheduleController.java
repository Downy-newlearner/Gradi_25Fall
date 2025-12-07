package kr.ac.dankook.microservices.academy.controller;


import kr.ac.dankook.microservices.academy.dto.AcademyScheduleDto;
import kr.ac.dankook.microservices.academy.dto.AcademyWithScheduleDto;
import kr.ac.dankook.microservices.academy.service.AcademyScheduleService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/academy-schedules")
@RequiredArgsConstructor
public class AcademyScheduleController {

    private final AcademyScheduleService service;

    @PostMapping
    public ResponseEntity<List<AcademyScheduleDto>> create(@RequestBody List<AcademyScheduleDto> dtos) {
        List<AcademyScheduleDto> saved = dtos.stream()
                .map(service::createSchedule)
                .collect(Collectors.toList());
        return ResponseEntity.ok(saved);
    }

    @GetMapping("/{academyCode}")
    public ResponseEntity<AcademyWithScheduleDto> getAcademyWithSchedules(@PathVariable String academyCode) {

        AcademyWithScheduleDto dto = service.getAcademyWithSchedules(academyCode);

        if (dto == null)
            return ResponseEntity.notFound().build();

        return ResponseEntity.ok(dto);
    }



//    @GetMapping("/{academyCode}")
//    public ResponseEntity<List<AcademyScheduleDto>> getByAcademyCode(@PathVariable String academyCode) {
//        List<AcademyScheduleDto> list = service.getSchedulesByAcademy(academyCode);
//        if (list.isEmpty()) return ResponseEntity.notFound().build();
//        return ResponseEntity.ok(list);
//    }

    @PutMapping("/academy/{academyCode}")
    public ResponseEntity<AcademyScheduleDto> update(
            @PathVariable String academyCode,
            @RequestBody AcademyScheduleDto dto) {

        return service.updateScheduleByAcademyCode(academyCode, dto)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @DeleteMapping("/academy/{academyCode}/{dayOfWeek}")
    public ResponseEntity<Void> delete(
            @PathVariable String academyCode,
            @PathVariable Integer dayOfWeek) {

        boolean deleted = service.deleteScheduleByAcademyCode(academyCode, dayOfWeek);
        if (deleted) return ResponseEntity.noContent().build();
        return ResponseEntity.notFound().build();
    }
}
