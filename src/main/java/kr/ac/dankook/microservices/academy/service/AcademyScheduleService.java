package kr.ac.dankook.microservices.academy.service;

import kr.ac.dankook.microservices.academy.dto.AcademyDto;
import kr.ac.dankook.microservices.academy.dto.AcademyScheduleDto;
import kr.ac.dankook.microservices.academy.dto.AcademyWithScheduleDto;
import kr.ac.dankook.microservices.academy.entity.Academy;
import kr.ac.dankook.microservices.academy.entity.AcademySchedule;
import kr.ac.dankook.microservices.academy.mapper.AcademyMapper;
import kr.ac.dankook.microservices.academy.mapper.AcademyScheduleMapper;
import kr.ac.dankook.microservices.academy.repository.AcademyRepository;
import kr.ac.dankook.microservices.academy.repository.AcademyScheduleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AcademyScheduleService {


    // academy 조회
    private final AcademyRepository academyRepository;
    private final AcademyScheduleRepository repository;
    private final AcademyScheduleMapper mapper;

    @Transactional
    public AcademyScheduleDto createSchedule(AcademyScheduleDto dto) {
        AcademySchedule schedule = mapper.toEntity(dto);
        return mapper.toDto(repository.save(schedule));
    }

//    public List<AcademyScheduleDto> getSchedulesByAcademy(String academyCode) {
//        return repository.findByAcademyCode(academyCode)
//                .stream()
//                .map(schedule -> mapper.toDto(schedule))
//                .collect(Collectors.toList());
//    }



    public AcademyWithScheduleDto getAcademyWithSchedules(String academyCode) {

        Academy academy = academyRepository.findByAcademyCode(academyCode)
                .orElse(null);

        if (academy == null) return null;

        AcademyDto academyDto = AcademyMapper.toDto(academy);

        // schedule 조회
        List<AcademySchedule> schedules = repository.findByAcademyCode(academyCode);

        List<AcademyScheduleDto> scheduleDtos = AcademyScheduleMapper.toDtoList(schedules);

        // 통합 DTO 반환
        return new AcademyWithScheduleDto(academyDto, scheduleDtos);
    }

    @Transactional
    public Optional<AcademyScheduleDto> updateScheduleByAcademyCode(String academyCode, AcademyScheduleDto dto) {
        return repository.findByAcademyCodeAndDayOfWeek(academyCode, dto.getDay_of_week())
                .map(existing -> {
                    mapper.updateEntity(dto, existing);
                    return mapper.toDto(repository.save(existing));
                });
    }


    @Transactional
    public boolean deleteScheduleByAcademyCode(String academyCode, Integer dayOfWeek) {
        return repository.findByAcademyCodeAndDayOfWeek(academyCode, dayOfWeek)
                .map(schedule -> {
                    repository.delete(schedule);
                    return true;
                }).orElse(false);
    }
}
