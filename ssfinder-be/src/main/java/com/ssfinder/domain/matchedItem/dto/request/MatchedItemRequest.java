package com.ssfinder.domain.matchedItem.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * packageName    : com.ssfinder.domain.matchedItem.dto.request<br>
 * fileName       : MatchedItemRequest.java<br>
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
    private Integer itemCategoryId;

    @NotBlank(message = "제목은 필수입니다")
    @Size(max = 100, message = "제목은 최대 100자까지 가능합니다")
    private String title;

    @NotBlank(message = "색상은 필수입니다")
    @Size(max = 10, message = "색상은 최대 10자까지 가능합니다")
    private String color;

    @Size(max = 65535, message = "상세설명의 최대 길이를 초과했습니다")
    private String detail;

    @NotBlank(message = "위치는 필수입니다")
    @Size(max = 100, message = "위치는 최대 100자까지 가능합니다")
    private String location;

    private String image;
    private Float threshold;
}