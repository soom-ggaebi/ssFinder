package com.ssfinder.domain.chat.dto;

import com.ssfinder.domain.founditem.entity.FoundItemStatus;
import com.ssfinder.domain.itemcategory.dto.ItemCategoryInfo;
import lombok.Builder;

/**
 * packageName    : com.ssfinder.domain.chat.dto<br>
 * fileName       : ChatRoomFoundItem.java<br>
 * author         : nature1216 <br>
 * date           : 2025-03-31<br>
 * description    : 채팅방에서 보여지는 습득물 정보를 담는 dto입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-31          nature1216          최초생성<br>
 * <br>
 */
@Builder
public record ChatRoomFoundItem(
        Integer foundItemId,
        ItemCategoryInfo category,
        String name,
        String color,
        String image,
        FoundItemStatus status
) {}
