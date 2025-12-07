package kr.ac.dankook.microservices.storage.service;

import kr.ac.dankook.microservices.storage.dto.FileRequestDto;
import kr.ac.dankook.microservices.storage.dto.StudentResponseDto;
import kr.ac.dankook.microservices.storage.dto.StudentResponseSaveRequest;
import lombok.RequiredArgsConstructor;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

@Service
@RequiredArgsConstructor
public class GradingServiceClient {

    @Qualifier("gradingWebClient")
    private final WebClient gradingWebClient;

    public void saveStudentResponse(Long studentResponseId, FileRequestDto dto, String jwtToken) {

        StudentResponseDto request = new StudentResponseDto();
        request.setStudent_response_id(studentResponseId);
        request.setAcademy_user_id(dto.getAcademy_user_id());
        request.setResponse_start_page(1);
        request.setResponse_end_page(dto.getTotal());
        request.setUnrecognized_response_count(0);
        request.setAssess_id(dto.getClass_id());
        request.setBook_id(dto.getAcademy_id());

        gradingWebClient.post()
                .uri("/student-responses")
                .header("Authorization", "Bearer " + jwtToken)
                .bodyValue(request)
                .retrieve()
                .bodyToMono(Void.class)
                .block();
    }


}

