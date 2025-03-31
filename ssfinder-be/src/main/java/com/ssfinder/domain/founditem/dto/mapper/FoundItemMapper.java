package com.ssfinder.domain.founditem.dto.mapper;

import com.ssfinder.domain.chat.dto.ChatRoomFoundItem;
import com.ssfinder.domain.founditem.dto.request.FoundItemRegisterRequest;
import com.ssfinder.domain.founditem.dto.request.FoundItemUpdateRequest;
import com.ssfinder.domain.founditem.dto.response.FoundItemDetailResponse;
import com.ssfinder.domain.founditem.dto.response.FoundItemRegisterResponse;
import com.ssfinder.domain.founditem.dto.response.FoundItemStatusUpdateResponse;
import com.ssfinder.domain.founditem.dto.response.FoundItemUpdateResponse;
import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.itemcategory.dto.ItemCategoryInfo;
import com.ssfinder.domain.itemcategory.entity.ItemCategory;
import org.mapstruct.*;

/**
 * packageName    : com.ssfinder.domain.foundItem.mapper<br>
 * fileName       : FoundItemMapper.java<br>
 * author         : leeyj<br>
 * date           : 2025-03-27<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-27          leeyj           최초생성<br>
 * <br>
 */
@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.WARN)
public interface FoundItemMapper {

    @Mapping(target = "image", ignore = true)
    FoundItem toEntity(FoundItemRegisterRequest request);

    @Mapping(source = "user.id", target = "userId")
    @Mapping(source = "itemCategory.id", target = "itemCategoryId")
    @Mapping(target = "latitude", expression = "java(foundItem.getCoordinates() != null ? foundItem.getCoordinates().getY() : null)")
    @Mapping(target = "longitude", expression = "java(foundItem.getCoordinates() != null ? foundItem.getCoordinates().getX() : null)")
    FoundItemRegisterResponse toResponse(FoundItem foundItem);

    @Mapping(source = "itemCategory.id", target = "itemCategoryId")
    @Mapping(target = "latitude", expression = "java(foundItem.getCoordinates() != null ? foundItem.getCoordinates().getY() : null)")
    @Mapping(target = "longitude", expression = "java(foundItem.getCoordinates() != null ? foundItem.getCoordinates().getX() : null)")
    FoundItemDetailResponse toDetailResponse(FoundItem foundItem);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "user", ignore = true)
    @Mapping(target = "itemCategory", expression = "java(createItemCategory(request.getItemCategoryId()))")
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "managementId", ignore = true)
    @Mapping(target = "image", ignore = true)
    void updateFoundItemFromRequest(FoundItemUpdateRequest request, @MappingTarget FoundItem foundItem);

    @Mapping(source = "itemCategory.id", target = "itemCategoryId")
    @Mapping(target = "image", ignore = true)
    @Mapping(target = "latitude", expression = "java(foundItem.getCoordinates() != null ? foundItem.getCoordinates().getY() : null)")
    @Mapping(target = "longitude", expression = "java(foundItem.getCoordinates() != null ? foundItem.getCoordinates().getX() : null)")
    FoundItemUpdateResponse toUpdateResponse(FoundItem foundItem);

    @Mapping(source = "id", target = "id")
    @Mapping(target = "status", expression = "java(foundItem.getStatus().name())")
    @Mapping(source = "updatedAt", target = "updatedAt")
    FoundItemStatusUpdateResponse toStatusUpdateResponse(FoundItem foundItem);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    @Mappings({
            @Mapping(source = "foundItem.id", target = "foundItemId"),
            @Mapping(source = "itemCategoryInfo", target = "category"),
            @Mapping(source = "foundItem.name", target = "name")
    })
    ChatRoomFoundItem mapToChatRoomFoundItem(FoundItem foundItem, ItemCategoryInfo itemCategoryInfo);

    default ItemCategory createItemCategory(Integer id) {
        ItemCategory itemCategory = new ItemCategory();
        itemCategory.setId(id);
        return itemCategory;
    }
}
