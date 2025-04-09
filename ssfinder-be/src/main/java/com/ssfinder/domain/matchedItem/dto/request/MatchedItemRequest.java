package com.ssfinder.domain.matchedItem.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * packageName    : com.ssfinder.domain.aimatching.dto.request<br>
 * fileName       : AiMatchingRequest.java<br>
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
public class MatchedItemRequest {
    private Integer lostItemId;
    private String category;
    private String itemName;
    private String color;
    private String content;
    private String location;
    private String imageUrl;         // 이미지 URL (선택적)
    private Float threshold;         // 유사도 임계값 (선택적, 기본값 0.7)
}