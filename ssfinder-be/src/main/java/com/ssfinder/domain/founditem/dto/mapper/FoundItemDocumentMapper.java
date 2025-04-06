package com.ssfinder.domain.founditem.dto.mapper;

import com.ssfinder.domain.founditem.dto.response.FoundItemDocumentDetailResponse;
import com.ssfinder.domain.founditem.entity.FoundItemDocument;
import org.mapstruct.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
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

    @Mapping(target = "foundAt", expression = "java(parseFoundAt(document.getFoundAt()))")
    @Mapping(target = "type", expression = "java(document.getManagementId() == null ? \"숨숨파인더\" : \"경찰청\")")
    @Mapping(target = "hasBookmark", ignore = true)
    @Mapping(target = "majorCategory", source = "categoryMajor")
    @Mapping(target = "minorCategory", source = "categoryMinor")
    FoundItemDocumentDetailResponse documentToDetailResponse(FoundItemDocument document);

    default LocalDate parseFoundAt(String dateStr) {
        if (dateStr == null) return null;

        try {
            return LocalDate.parse(dateStr);
        } catch (Exception e) {
            try {
                return LocalDateTime.parse(dateStr, DateTimeFormatter.ISO_DATE_TIME).toLocalDate();
            } catch (Exception ex) {
                return null;
            }
        }
    }
}