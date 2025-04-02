package com.ssfinder.domain.founditem.dto.mapper;

import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.founditem.entity.FoundItemDocument;
import com.ssfinder.domain.item.entity.ItemCategory;
import org.mapstruct.*;
import org.springframework.data.elasticsearch.core.geo.GeoPoint;

import java.time.format.DateTimeFormatter;

/**
 * packageName    : com.ssfinder.domain.founditem.dto.mapper<br>
 * fileName       : FoundItemDocumentMapper.java<br>
 * author         : leeyj<br>
 * date           : 2025-03-31<br>
 * description    : FoundItem 엔티티를 ElasticSearch 문서로 변환하는 Mapper<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-31          leeyj           최초생성<br>
 * <br>
 */
@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface FoundItemDocumentMapper {

    /**
     * FoundItem 엔티티를 ElasticSearch 문서로 변환
     *
     * @param foundItem FoundItem 엔티티
     * @param hdfsImagePath HDFS에 저장된 이미지 경로
     * @return FoundItemDocument 객체
     */
    @Mapping(target = "id", expression = "java(foundItem.getId().toString())")
    @Mapping(target = "mysqlId", expression = "java(foundItem.getId().toString())")
    @Mapping(source = "foundAt", target = "foundAt", dateFormat = "yyyy-MM-dd'T'HH:mm:ss")
    @Mapping(target = "latitude", expression = "java(foundItem.getCoordinates() != null ? foundItem.getCoordinates().getY() : null)")
    @Mapping(target = "longitude", expression = "java(foundItem.getCoordinates() != null ? foundItem.getCoordinates().getX() : null)")
    @Mapping(target = "locationGeo", expression = "java(createGeoPoint(foundItem))")
    @Mapping(source = "status", target = "status")
    @Mapping(source = "managementId", target = "managementId")
    @Mapping(target = "categoryMajor", ignore = true)
    @Mapping(target = "categoryMinor", ignore = true)
    @Mapping(source = "detail", target = "detail")
    @Mapping(source = "phone", target = "phone")
    @Mapping(source = "storedAt", target = "storedAt")
    @Mapping(source = "color", target = "color")
    @Mapping(source = "location", target = "location")
    @Mapping(source = "name", target = "name")
    @Mapping(source = "image", target = "image")
    FoundItemDocument toDocument(FoundItem foundItem, @Context String hdfsImagePath);

    @AfterMapping
    default void afterMapping(FoundItem foundItem, @MappingTarget FoundItemDocument document,
                              @Context String hdfsImagePath) {

        document.setImageHdfs(hdfsImagePath);

        if (foundItem.getItemCategory() != null) {
            ItemCategory category = foundItem.getItemCategory();

            if (category.getItemCategory() == null) {
                document.setCategoryMajor(category.getName());
                document.setCategoryMinor(null);
            } else {
                document.setCategoryMinor(category.getName());
                document.setCategoryMajor(category.getItemCategory().getName());
            }
        }
    }

    default GeoPoint createGeoPoint(FoundItem item) {
        if (item.getCoordinates() == null) return null;
        return new GeoPoint(item.getCoordinates().getY(), item.getCoordinates().getX());
    }

    default String mapStatus(Enum<?> status) {
        return status != null ? status.name() : null;
    }

    default String formatDate(java.time.temporal.Temporal date) {
        if (date == null) return null;
        if (date instanceof java.time.LocalDate) {
            return ((java.time.LocalDate) date).format(DateTimeFormatter.ISO_DATE);
        } else if (date instanceof java.time.LocalDateTime) {
            return ((java.time.LocalDateTime) date).format(DateTimeFormatter.ISO_DATE_TIME);
        }
        return date.toString();
    }
}