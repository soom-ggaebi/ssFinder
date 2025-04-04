package com.ssfinder.domain.aianalyze.dto.response;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.io.Serializable;

/**
 * packageName    : com.ssfinder.domain.aianalyze.dto.response<br>
 * fileName       : AiAnalyzeResponse*.java<br>
 * author         : sonseohy<br>
 * date           : 2025-04-04<br>
 * description    : AI 분석 결과 응답 DTO<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-04          sonseohy           최초생성<br>
 * <br>
 */
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true) // 알 수 없는 필드 무시
public class AiAnalyzeResponse implements Serializable {
    private String title;
    private String category;
    private String color;
    private String material;
    private String brand;
    private String description;
    private String distinctiveFeatures;

    // FastAPI 응답 포맷에 맞춰 중첩 클래스로 정의
    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class AiAnalyzeApiResponse {
        private String status;
        private AiAnalyzeResponse data;
    }
}