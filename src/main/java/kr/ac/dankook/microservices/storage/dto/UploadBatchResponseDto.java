package kr.ac.dankook.microservices.storage.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class UploadBatchResponseDto {
    private Long studentResponseId;
    private List<String> presignedUrls;
    private String message;

    public UploadBatchResponseDto(Long studentResponseId, List<String> presignedUrls) {
        this.studentResponseId = studentResponseId;
        this.presignedUrls = presignedUrls;
        this.message = "success";
    }

    public UploadBatchResponseDto(Long studentResponseId, String message) {
        this.studentResponseId = studentResponseId;
        this.presignedUrls = null;
        this.message = message;
    }
}
