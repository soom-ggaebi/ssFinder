package com.ssfinder.domain.matchedItem.dto.response;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.*;

import java.util.List;

/**
 * packageName    : com.ssfinder.domain.matchedItem.dto.response<br>
 * fileName       : MatchedItemResponse.java<br>
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
@ToString
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class MatchedItemResponse {
    private boolean success;           // 요청 성공 여부
    private String message;            // 응답 메시지
    private MatchingResult result;     // 매칭 결과

    @Getter
    @Builder
    @ToString
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
    @ToString
    @NoArgsConstructor
    @AllArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class MatchItem {
        private Integer lostItemId;        // 분실물 ID
        private Integer foundItemId;       // 습득물 ID
        private FoundItemInfo item;        // 습득물 정보 - 분실물 정보
        private float similarity;          // 유사도 점수
    }

    @Getter
    @Builder
    @ToString
    @NoArgsConstructor
    @AllArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class FoundItemInfo {
        private Integer id;                  // 습득물 ID
        private Integer user_id;
        private Integer item_category_id;
        private String title;
        private String color;
        private String lost_at;
        private String location;
        private String detail;
        private String image;
        private String status;
        private String stored_at;
    }
}