package com.ssfinder.domain.found.dto.mapper;

import com.ssfinder.domain.found.dto.response.FoundItemBookmarkResponse;
import com.ssfinder.domain.found.entity.FoundItem;
import com.ssfinder.domain.found.entity.FoundItemBookmark;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.WARN)
public interface FoundItemBookmarkMapper {

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "user", ignore = true)
    @Mapping(target = "foundItem", expression = "java(createFoundItem(foundItemId))")
    FoundItemBookmark toEntity(Integer foundItemId);

    @Mapping(source = "user.id", target = "userId")
    @Mapping(source = "foundItem.id", target = "foundItemId")
    FoundItemBookmarkResponse toResponse(FoundItemBookmark bookmark);

    default FoundItem createFoundItem(Integer id) {
        FoundItem foundItem = new FoundItem();
        foundItem.setId(id);
        return foundItem;
    }
}