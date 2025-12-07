package kr.ac.dankook.microservices.academy.controller;

import kr.ac.dankook.microservices.academy.dto.AcademyImageDto;
import kr.ac.dankook.microservices.academy.service.AcademyImageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.List;

@RestController
public class AcademyImageController {

    @Autowired
    private AcademyImageService academyImageService;



    @GetMapping("/images/{academyCode}")
    public AcademyImageDto getAcademyImages(@PathVariable String academyCode) {
        return academyImageService.getAcademyImages(academyCode);
    }

    @GetMapping("images/main/{academyCodes}")
    public List<AcademyImageDto> getMainImages(@PathVariable String academyCodes) {
        List<String> codes = Arrays.asList(academyCodes.split(","));
        return academyImageService.getMainImages(codes);
    }

}
