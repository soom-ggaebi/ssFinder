package com.ssfinder.domain.itemcategory.dto;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.*;

/**
 * packageName    : com.ssfinder.domain.itemcategory.dto<br>
 * fileName       : ItemCategoryInfo.java<br>
 * author         : nature1216 <br>
 * date           : 2025-04-01<br>
 * description    : item category 정보 dto입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-01         nature1216          최초생성<br>
 * <br>
 */
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Getter
@Setter
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class ItemCategoryInfo {
    private Integer id;
    private String name;
    private Integer parentId;
    private String parentName;
}
