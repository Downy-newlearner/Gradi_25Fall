package kr.ac.dankook.microservices.storage.dto;

import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class FileRequestDto {
    private Long student_response_id;
    private Long academy_user_id;
    private Long user_id;
    private Long class_id;
    private Long academy_id;
    private String file_name;
    private String url;

    // 배치용 필드 추가
    private Integer index;      // 현재 파일 순서 (1부터 시작)
    private Integer total; // 배치 전체 개수
}
