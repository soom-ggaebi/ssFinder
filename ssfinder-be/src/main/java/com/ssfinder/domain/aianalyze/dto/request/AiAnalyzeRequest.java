package com.ssfinder.domain.aianalyze.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * packageName    : com.ssfinder.domain.aianalyze.dto.request<br>
 * fileName       : AiAnalyzeRequest*.java<br>
 * author         : sonseohy<br>
 * date           : 2025-04-04<br>
 * description    : AI 분석 요청 DTO<br>
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
public class AiAnalyzeRequest {
    private byte[] file;          // 이미지 바이너리 데이터
    private String filename;      // 원본 파일명
}