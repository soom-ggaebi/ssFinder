package com.ssfinder.domain.found.dto.mapper;

import com.ssfinder.domain.found.dto.request.FoundItemRegisterRequest;
import com.ssfinder.domain.found.dto.request.FoundItemUpdateRequest;
import com.ssfinder.domain.found.dto.response.FoundItemDetailResponse;
import com.ssfinder.domain.found.dto.response.FoundItemRegisterResponse;
import com.ssfinder.domain.found.dto.response.FoundItemUpdateResponse;
import com.ssfinder.domain.found.entity.FoundItem;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;
import org.mapstruct.ReportingPolicy;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.WARN)
public interface FoundItemMapper {

    FoundItem toEntity(FoundItemRegisterRequest request);

    @Mapping(source = "user.id", target = "userId")
    @Mapping(source = "itemCategory.id", target = "itemCategoryId")
    FoundItemRegisterResponse toResponse(FoundItem foundItem);

    @Mapping(source = "itemCategory.id", target = "itemCategoryId")
    FoundItemDetailResponse toDetailResponse(FoundItem foundItem);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "user", ignore = true)
    @Mapping(target = "itemCategory", expression = "java(createItemCategory(request.getItemCategoryId()))")
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    @Mapping(target = "managementId", ignore = true)
    void updateFoundItemFromRequest(FoundItemUpdateRequest request, @MappingTarget FoundItem foundItem);

    @Mapping(source = "itemCategory.id", target = "itemCategoryId")
    FoundItemUpdateResponse toUpdateResponse(FoundItem foundItem);

    default com.ssfinder.domain.item.entity.ItemCategory createItemCategory(Integer id) {
        com.ssfinder.domain.item.entity.ItemCategory itemCategory = new com.ssfinder.domain.item.entity.ItemCategory();
        itemCategory.setId(id);
        return itemCategory;
    }
}
