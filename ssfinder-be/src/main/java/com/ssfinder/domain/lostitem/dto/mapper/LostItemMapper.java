package com.ssfinder.domain.lostitem.dto.mapper;

import com.ssfinder.domain.item.entity.ItemCategory;
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

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.WARN)
public interface LostItemMapper {

    LostItem toEntity(LostItemRegisterRequest request);

    @Mapping(source = "user.id", target = "userId")
    @Mapping(source = "itemCategory.id", target = "itemCategoryId")
    @Mapping(target = "latitude", expression = "java(lostItem.getCoordinates() != null ? lostItem.getCoordinates().getY() : null)")
    @Mapping(target = "longitude", expression = "java(lostItem.getCoordinates() != null ? lostItem.getCoordinates().getX() : null)")
    LostItemResponse toResponse(LostItem lostItem);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "user", ignore = true)
    @Mapping(target = "itemCategory", expression = "java(createItemCategory(request.getItemCategoryId()))")
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)

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
}
