package com.ssfinder.domain.aimatching.dto.response;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * packageName    : com.ssfinder.domain.aimatching.dto.response<br>
 * fileName       : AiMatchingResponse.java<br>
 * author         : sonseohy<br>
 * date           : 2025-04-09<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-09          sonseohy           최초생성<br>
 * <br>
 */
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class AiMatchingResponse {
    private boolean success;           // 요청 성공 여부
    private String message;            // 응답 메시지
    private MatchingResult result;     // 매칭 결과

    @Getter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class MatchingResult {
        private int totalMatches;             // 매칭된 항목 수
        private float similarityThreshold;    // 유사도 임계값
        private List<MatchItem> matches;      // 매칭된 항목 목록
    }

    @Getter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class MatchItem {
        private Integer lostItemId;        // 분실물 ID
        private Integer foundItemId;       // 습득물 ID
        private FoundItemInfo item;        // 습득물 정보
        private float similarity;          // 유사도 점수
    }

    @Getter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class FoundItemInfo {
        private Integer id;                  // 습득물 ID
        private String name;                 // 습득물 이름
        private String category;             // 카테고리
        private String color;                // 색상
        private String location;             // 습득 장소
        private String detail;               // 상세 설명
        private String image;                // 이미지 URL
        private String status;               // 상태
        private String storedAt;             // 보관 장소
    }
}