package com.ssfinder.domain.founditem.dto.mapper;

import com.ssfinder.domain.founditem.dto.response.FoundItemBookmarkResponse;
import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.founditem.entity.FoundItemBookmark;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

/**
 * packageName    : com.ssfinder.domain.foundItem.mapper<br>
 * fileName       : FoundItemBookmarkMapper.java<br>
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