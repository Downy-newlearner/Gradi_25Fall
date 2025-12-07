package kr.ac.dankook.microservices.storage.dto;

import lombok.*;



@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class StudentResponseSaveRequest {
    private Long studentResponseId;
    private Long academyUserId;
    private Long userId;
    private Long classId;
    private Long academyId;
    private Integer totalFiles;
}
