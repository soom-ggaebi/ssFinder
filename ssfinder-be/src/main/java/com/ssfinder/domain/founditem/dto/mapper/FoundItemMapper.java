package com.ssfinder.domain.founditem.dto.mapper;

import com.ssfinder.domain.chat.dto.ChatRoomFoundItem;
import com.ssfinder.domain.founditem.dto.request.FoundItemRegisterRequest;
import com.ssfinder.domain.founditem.dto.request.FoundItemUpdateRequest;
import com.ssfinder.domain.founditem.dto.response.FoundItemUpdateResponse;
import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.founditem.entity.FoundItemDocument;
import com.ssfinder.domain.founditem.entity.FoundItemStatus;
import com.ssfinder.domain.itemcategory.dto.ItemCategoryInfo;
import com.ssfinder.domain.itemcategory.entity.ItemCategory;
import com.ssfinder.domain.user.entity.User;
import org.locationtech.jts.geom.Point;
import org.mapstruct.*;
import org.springframework.data.elasticsearch.core.geo.GeoPoint;

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
@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface FoundItemMapper {

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "user", source = "user")
    @Mapping(target = "itemCategory", source = "itemCategory")
    @Mapping(target = "name", source = "request.name")
    @Mapping(target = "foundAt", source = "request.foundAt")
    @Mapping(target = "location", source = "request.location")
    @Mapping(target = "color", source = "request.color")
    @Mapping(target = "detail", source = "request.detail")
    @Mapping(target = "status", expression = "java(mapStatus(request.getStatus()))")
    @Mapping(target = "createdAt", expression = "java(java.time.LocalDateTime.now())")
    @Mapping(target = "updatedAt", expression = "java(java.time.LocalDateTime.now())")
    @Mapping(target = "image", ignore = true)
    @Mapping(target = "coordinates", ignore = true)
    @Mapping(target = "managementId", ignore = true)
    @Mapping(target = "storedAt", expression = "java(\"처리중\")")
    FoundItem requestToEntity(FoundItemRegisterRequest request, User user, ItemCategory itemCategory);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "mysqlId", expression = "java(String.valueOf(foundItem.getId()))")
    @Mapping(target = "userId", expression = "java(foundItem.getUser() != null ? String.valueOf(foundItem.getUser().getId()) : null)")
    @Mapping(target = "categoryMajor", expression = "java(mapCategoryMajor(foundItem))")
    @Mapping(target = "categoryMinor", expression = "java(mapCategoryMinor(foundItem))")
    @Mapping(target = "name", source = "foundItem.name")
    @Mapping(target = "foundAt", expression = "java(foundItem.getFoundAt() != null ? foundItem.getFoundAt().toString() : null)")
    @Mapping(target = "color", source = "foundItem.color")
    @Mapping(target = "status", expression = "java(foundItem.getStatus() != null ? foundItem.getStatus().toString() : null)")
    @Mapping(target = "location", source = "foundItem.location")
    @Mapping(target = "phone", source = "foundItem.phone")
    @Mapping(target = "detail", source = "foundItem.detail")
    @Mapping(target = "image", source = "foundItem.image")
    @Mapping(target = "storedAt", source = "foundItem.storedAt")
    @Mapping(target = "managementId", source = "foundItem.managementId")
    @Mapping(target = "latitude", expression = "java(foundItem.getCoordinates() != null ? foundItem.getCoordinates().getY() : null)")
    @Mapping(target = "longitude", expression = "java(foundItem.getCoordinates() != null ? foundItem.getCoordinates().getX() : null)")
    @Mapping(target = "locationGeo", expression = "java(mapGeoPoint(foundItem.getCoordinates()))")
    @Mapping(target = "imageHdfs", ignore = true)
    FoundItemDocument entityToDocument(FoundItem foundItem);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "user", ignore = true)
    @Mapping(target = "itemCategory", source = "itemCategory")
    @Mapping(target = "name", source = "request.name")
    @Mapping(target = "foundAt", source = "request.foundAt")
    @Mapping(target = "location", source = "request.location")
    @Mapping(target = "color", source = "request.color")
    @Mapping(target = "detail", source = "request.detail")
    @Mapping(target = "storedAt", source = "request.storedAt")
    @Mapping(target = "updatedAt", expression = "java(java.time.LocalDateTime.now())")
    @Mapping(target = "image", ignore = true)
    @Mapping(target = "coordinates", ignore = true)
    @Mapping(target = "status", ignore = true)
    @Mapping(target = "phone", ignore = true)
    @Mapping(target = "managementId", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    void updateEntityFromRequest(FoundItemUpdateRequest request, @MappingTarget FoundItem foundItem, ItemCategory itemCategory);

    @Mapping(target = "userId", expression = "java(foundItem.getUser().getId())")
    @Mapping(target = "itemCategoryId", expression = "java(foundItem.getItemCategory().getId())")
    @Mapping(target = "status", expression = "java(foundItem.getStatus().toString())")
    @Mapping(target = "latitude", expression = "java(foundItem.getCoordinates() != null ? foundItem.getCoordinates().getY() : null)")
    @Mapping(target = "longitude", expression = "java(foundItem.getCoordinates() != null ? foundItem.getCoordinates().getX() : null)")
    FoundItemUpdateResponse entityToUpdateResponse(FoundItem foundItem);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    @Mappings({
            @Mapping(source = "foundItem.id", target = "id"),
            @Mapping(source = "itemCategoryInfo", target = "category"),
            @Mapping(source = "foundItem.name", target = "name")
    })
    ChatRoomFoundItem mapToChatRoomFoundItem(FoundItem foundItem, ItemCategoryInfo itemCategoryInfo);

    default FoundItemStatus mapStatus(String status) {
        if (status == null) {
            return FoundItemStatus.STORED;
        }
        try {
            return FoundItemStatus.valueOf(status.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return FoundItemStatus.STORED;
        }
    }

    default String mapCategoryMajor(FoundItem foundItem) {
        if (foundItem.getItemCategory() == null) {
            return null;
        }

        return foundItem.getItemCategory().getItemCategory() != null
                ? foundItem.getItemCategory().getItemCategory().getName()
                : foundItem.getItemCategory().getName();
    }

    default String mapCategoryMinor(FoundItem foundItem) {
        if (foundItem.getItemCategory() == null) {
            return null;
        }

        return foundItem.getItemCategory().getItemCategory() != null
                ? foundItem.getItemCategory().getName()
                : null;
    }

    default GeoPoint mapGeoPoint(Point point) {
        if (point == null) {
            return null;
        }
        return new GeoPoint(point.getY(), point.getX());
    }
}