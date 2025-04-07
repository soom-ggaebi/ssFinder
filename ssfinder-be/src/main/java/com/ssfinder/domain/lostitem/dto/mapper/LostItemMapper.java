package com.ssfinder.domain.lostitem.dto.mapper;

import com.ssfinder.domain.itemcategory.entity.ItemCategory;
import com.ssfinder.domain.lostitem.dto.request.LostItemRegisterRequest;
import com.ssfinder.domain.lostitem.dto.request.LostItemUpdateRequest;
import com.ssfinder.domain.lostitem.dto.response.LostItemResponse;
import com.ssfinder.domain.lostitem.dto.response.LostItemStatusUpdateResponse;
import com.ssfinder.domain.lostitem.dto.response.LostItemUpdateResponse;
import com.ssfinder.domain.lostitem.entity.LostItem;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;
import org.mapstruct.ReportingPolicy;

/**
 * packageName    : com.ssfinder.domain.lostItem.mapper<br>
 * fileName       : LostItemMapper.java<br>
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
public interface LostItemMapper {

    @Mapping(target = "image", ignore = true)
    LostItem toEntity(LostItemRegisterRequest request);

    @Mapping(source = "user.id", target = "userId")
    @Mapping(target = "latitude", expression = "java(lostItem.getCoordinates() != null ? lostItem.getCoordinates().getY() : null)")
    @Mapping(target = "longitude", expression = "java(lostItem.getCoordinates() != null ? lostItem.getCoordinates().getX() : null)")
    @Mapping(target = "majorItemCategory", expression = "java(mapCategoryMajor(lostItem))")
    @Mapping(target = "minorItemCategory", expression = "java(mapCategoryMinor(lostItem))")
    LostItemResponse toResponse(LostItem lostItem);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "user", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "image", ignore = true)
    void updateLostItemFromRequest(LostItemUpdateRequest request, @MappingTarget LostItem lostItem);

    @Mapping(source = "itemCategory.id", target = "itemCategoryId")
    @Mapping(target = "latitude", expression = "java(lostItem.getCoordinates() != null ? lostItem.getCoordinates().getY() : null)")
    @Mapping(target = "longitude", expression = "java(lostItem.getCoordinates() != null ? lostItem.getCoordinates().getX() : null)")
    LostItemUpdateResponse toUpdateResponse(LostItem lostItem);

    @Mapping(source = "id", target = "id")
    @Mapping(target = "status", expression = "java(lostItem.getStatus().name())")
    @Mapping(source = "updatedAt", target = "updatedAt")
    LostItemStatusUpdateResponse toStatusUpdateResponse(LostItem lostItem);

    default ItemCategory createItemCategory(Integer id) {
        ItemCategory itemCategory = new ItemCategory();
        itemCategory.setId(id);
        return itemCategory;
    }

    default String mapCategoryMajor(LostItem lostItem) {
        if (lostItem.getItemCategory() == null) {
            return null;
        }
        return lostItem.getItemCategory().getItemCategory() != null
                ? lostItem.getItemCategory().getItemCategory().getName()
                : lostItem.getItemCategory().getName();
    }

    default String mapCategoryMinor(LostItem lostItem) {
        if (lostItem.getItemCategory() == null) {
            return null;
        }
        return lostItem.getItemCategory().getItemCategory() != null
                ? lostItem.getItemCategory().getName()
                : null;
    }
}
