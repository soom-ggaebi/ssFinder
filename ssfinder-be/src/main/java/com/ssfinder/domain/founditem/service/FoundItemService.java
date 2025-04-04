package com.ssfinder.domain.founditem.service;

import com.ssfinder.domain.founditem.dto.mapper.FoundItemDocumentMapper;
import com.ssfinder.domain.founditem.dto.mapper.FoundItemMapper;
import com.ssfinder.domain.founditem.dto.request.FoundItemRegisterRequest;
import com.ssfinder.domain.founditem.dto.request.FoundItemStatusUpdateRequest;
import com.ssfinder.domain.founditem.dto.request.FoundItemUpdateRequest;
import com.ssfinder.domain.founditem.dto.request.FoundItemViewportRequest;
import com.ssfinder.domain.founditem.dto.response.*;
import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.founditem.entity.FoundItemDocument;
import com.ssfinder.domain.founditem.entity.FoundItemStatus;
import com.ssfinder.domain.founditem.repository.FoundItemDocumentRepository;
import com.ssfinder.domain.founditem.repository.FoundItemRepository;
import com.ssfinder.domain.item.entity.ItemCategory;
import com.ssfinder.domain.item.repository.ItemCategoryRepository;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.service.UserService;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import com.ssfinder.global.common.service.*;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.data.elasticsearch.core.ElasticsearchOperations;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.core.query.Criteria;
import org.springframework.data.elasticsearch.core.query.CriteriaQuery;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.*;
import java.util.stream.Collectors;

/**
 * packageName    : com.ssfinder.domain.found.service<br>
 * fileName       : FoundService.java<br>
 * author         : joker901010<br>
 * date           : 2025-03-19<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          joker901010           최초생성<br>
 * 2025-03-27          joker901010           코드리뷰 수정<br>
 * <br>
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class FoundItemService {

    private final FoundItemRepository foundItemRepository;
    private final FoundItemDocumentRepository foundItemDocumentRepository;
    private final FoundItemMapper foundItemMapper;
    private final UserService userService;
    private final ItemCategoryRepository itemCategoryRepository;
    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);
    private final ElasticsearchOperations elasticsearchOperations;
    private final ImageHandler imageHandler;
    private final ElasticsearchAsyncService elasticsearchAsyncService;
    private final FoundItemBookmarkService foundItemBookmarkService;
    private final FoundItemDocumentMapper foundItemDocumentMapper;
    private final S3Service s3Service;

    // 습득물 데이터 저장
    @Transactional
    public FoundItemDocument registerFoundItem(int userId, FoundItemRegisterRequest request) {

        User user = userService.findUserById(userId);

        ItemCategory itemCategory = itemCategoryRepository.findById(request.getItemCategoryId())
                .orElseThrow(() -> new CustomException(ErrorCode.CATEGORY_NOT_FOUND));

        FoundItem foundItem = foundItemMapper.requestToEntity(request, user, itemCategory);

        setCoordinates(foundItem, request);

        String imageUrl = imageHandler.processAndUploadImage(request.getImage(), "found");
        foundItem.setImage(imageUrl);

        FoundItem savedItem = foundItemRepository.save(foundItem);

        elasticsearchAsyncService.saveFoundItemToElasticsearch(savedItem);

        return foundItemMapper.entityToDocument(savedItem);
    }


    // 상세조회
    @Transactional(readOnly = true)
    public FoundItemDocumentDetailResponse getFoundItemDetail(Integer userId ,int foundId) {

        FoundItemDocument document = foundItemDocumentRepository.findById(String.valueOf(foundId))
                .orElseThrow(() -> new CustomException(ErrorCode.FOUND_ITEM_NOT_FOUND));

        FoundItemDocumentDetailResponse response = foundItemDocumentMapper.documentToDetailResponse(document);

        if (Objects.nonNull(userId)) {
            boolean isBookmarked = foundItemBookmarkService.isItemBookmarkedByUser(userId, foundId);
            response.setHasBookmark(isBookmarked);
        } else {
            response.setHasBookmark(false);
        }

        return response;
    }

    // 습득물 수정
    @Transactional
    public FoundItemUpdateResponse updateFoundItem(int userId, int foundId, FoundItemUpdateRequest request){

        FoundItem foundItem = foundItemRepository.findById(foundId)
                .orElseThrow(() -> new CustomException(ErrorCode.FOUND_ITEM_NOT_FOUND));

        if (!foundItem.getUser().getId().equals(userId)) {
            throw new CustomException(ErrorCode.FOUND_ITEM_ACCESS_DENIED);
        }

        ItemCategory itemCategory = itemCategoryRepository.findById(request.getItemCategoryId())
                .orElseThrow(() -> new CustomException(ErrorCode.CATEGORY_NOT_FOUND));

        if (request.getImage() != null && !request.getImage().isEmpty()) {
            if (foundItem.getImage() != null && !foundItem.getImage().isEmpty()) {
                s3Service.deleteFile(foundItem.getImage());
            }

            String imageUrl = imageHandler.processAndUploadImage(request.getImage(), "found");
            foundItem.setImage(imageUrl);
        }

        if (request.getLatitude() != null && request.getLongitude() != null) {
            GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);
            Point coordinates = geometryFactory.createPoint(
                    new Coordinate(request.getLongitude(), request.getLatitude())
            );
            foundItem.setCoordinates(coordinates);
        }

        foundItemMapper.updateEntityFromRequest(request, foundItem, itemCategory);

        FoundItem updatedFoundItem = foundItemRepository.save(foundItem);
        elasticsearchAsyncService.saveFoundItemToElasticsearch(updatedFoundItem);

        return foundItemMapper.entityToUpdateResponse(updatedFoundItem);
    }

    // 습득물 삭제
    @Transactional
    public void deleteFoundItem(int userId, int foundId) {

        FoundItem foundItem = foundItemRepository.findById(foundId)
                .orElseThrow(() -> new CustomException(ErrorCode.FOUND_ITEM_NOT_FOUND));

        if(foundItem.getUser().getId()!=userId) {
            throw new CustomException(ErrorCode.FOUND_ITEM_ACCESS_DENIED);
        }

        if (Objects.nonNull(foundItem.getImage())) {
            try {
                s3Service.deleteFile(foundItem.getImage());
            } catch (Exception e) {
                log.error("S3 이미지 삭제 실패: {}, 오류={}", foundItem.getImage(), e.getMessage());
            }
        }

        try {
            log.info("관련 북마크 삭제 시작: FoundItemId={}", foundId);
            foundItemBookmarkService.deleteAllBookmarksByFoundItemId(foundId);
            log.info("관련 북마크 삭제 완료: FoundItemId={}", foundId);
        } catch (Exception e) {
            log.error("북마크 삭제 실패 (계속 진행): FoundItemId={}, 오류={}", foundId, e.getMessage());
        }

        foundItemRepository.delete(foundItem);

        String esDocumentId = String.valueOf(foundId);

        elasticsearchAsyncService.deleteFoundItemFromElasticsearch(esDocumentId);
    }

    // 습득물 상태 수정
    @Transactional
    public FoundItemDocumentDetailResponse updateFoundItemStatus(int userId, int foundId, FoundItemStatusUpdateRequest request) {

        FoundItem foundItem = foundItemRepository.findById(foundId)
                .orElseThrow(() -> new CustomException(ErrorCode.FOUND_ITEM_NOT_FOUND));

        if (!foundItem.getUser().getId().equals(userId)) {
            throw new CustomException(ErrorCode.FOUND_ITEM_ACCESS_DENIED);
        }

        FoundItemStatus newStatus = FoundItemStatus.valueOf(request.getStatus());
        foundItem.setStatus(newStatus);
        foundItem.setUpdatedAt(LocalDateTime.now());

        elasticsearchAsyncService.saveFoundItemToElasticsearch(foundItem);

        FoundItemDocument response = foundItemMapper.entityToDocument(foundItem);

        return foundItemDocumentMapper.documentToDetailResponse(response);
    }

    // 내 습득물 조회
    @Transactional(readOnly = true)
    public Page<FoundItemDetailResponse> getMyFoundItems(int userId, Pageable pageable) {
        String userIdStr = String.valueOf(userId);

        try {
            Criteria criteria = new Criteria("user_id").exists().is(userIdStr);

            CriteriaQuery query = new CriteriaQuery(criteria).setPageable(pageable);

            SearchHits<FoundItemDocument> searchHits = elasticsearchOperations.search(
                    query, FoundItemDocument.class);

            List<FoundItemDetailResponse> content = searchHits.getSearchHits().stream()
                    .map(SearchHit::getContent)
                    .map(this::convertToDetailResponse)
                    .collect(Collectors.toList());

            return new PageImpl<>(content, pageable, searchHits.getTotalHits());
        } catch (Exception e) {
            System.err.println("Elasticsearch 검색 중 오류 발생: " + e.getMessage());
            return new PageImpl<>(Collections.emptyList(), pageable, 0);
        }
    }

    // 뷰포트 기준 전체 조회
    @Transactional(readOnly = true)
    public List<FoundItemDocumentDetailResponse> getFoundItemsByViewport(FoundItemViewportRequest viewportRequest) {

        Criteria latCriteria = new Criteria("location_geo.lat")
                .between(viewportRequest.getMinLatitude(), viewportRequest.getMaxLatitude());

        Criteria lonCriteria = new Criteria("location_geo.lon")
                .between(viewportRequest.getMinLongitude(), viewportRequest.getMaxLongitude());

        Criteria criteria = latCriteria.and(lonCriteria);
        CriteriaQuery query = new CriteriaQuery(criteria);

        SearchHits<FoundItemDocument> searchHits = elasticsearchOperations.search(query, FoundItemDocument.class);

        return searchHits.getSearchHits().stream().map(hit -> {
            FoundItemDocument doc = hit.getContent();
            FoundItemDocumentDetailResponse response = new FoundItemDocumentDetailResponse();

            boolean type = true;
            if (Objects.nonNull(doc.getManagementId())) {
                type = false;
            }

            response.setId(doc.getMysqlId());
            response.setUserId(doc.getUserId());
            response.setMajorCategory(doc.getCategoryMajor());
            response.setMinorCategory(doc.getCategoryMinor());
            response.setName(doc.getName());
            response.setColor(doc.getColor());
            response.setStatus(doc.getStatus());
            response.setLocation(doc.getLocation());
            response.setPhone(doc.getPhone());
            response.setDetail(doc.getDetail());
            response.setImage(doc.getImage());
            response.setStoredAt(doc.getStoredAt());
            response.setLatitude(doc.getLatitude());
            response.setLongitude(doc.getLongitude());
            response.setType(type);

            if (doc.getFoundAt() != null && doc.getFoundAt().length() >= 10) {
                try {
                    response.setFoundAt(LocalDate.parse(doc.getFoundAt().substring(0, 10)));
                } catch (DateTimeParseException e) {
                    response.setFoundAt(null);
                }
            } else {
                response.setFoundAt(null);
            }

            response.setCreatedAt(null);
            response.setUpdatedAt(null);

            return response;
        }).collect(Collectors.toList());
    }


    public List<FoundItem> getStoredItemsFoundDaysAgo(int daysAgo) {
        return foundItemRepository.findByFoundAtAndStatus(LocalDate.now().minusDays(daysAgo), FoundItemStatus.STORED);
    }

    private FoundItemDetailResponse convertToDetailResponse(FoundItemDocument document) {
        FoundItemDetailResponse response = new FoundItemDetailResponse();

        response.setId(document.getMysqlId() != null ? Integer.valueOf(document.getMysqlId()) : null);

        response.setUserId(document.getUserId() != null ? Integer.valueOf(document.getUserId()) : null);

        response.setMajorCategory(document.getCategoryMajor());
        response.setMinorCategory(document.getCategoryMinor());
        response.setName(document.getName());

        response.setFoundAt(document.getFoundAt() != null
                ? LocalDateTime.parse(document.getFoundAt(), DateTimeFormatter.ISO_LOCAL_DATE_TIME).toLocalDate()
                : null);

        response.setLocation(document.getLocation());
        response.setColor(document.getColor());
        response.setStatus(document.getStatus());
        response.setDetail(document.getDetail());
        response.setImage(document.getImage());
        response.setStoredAt(document.getStoredAt());

        response.setCreatedAt(LocalDateTime.now());
        response.setUpdatedAt(LocalDateTime.now());

        response.setLatitude(document.getLatitude());
        response.setLongitude(document.getLongitude());

        return response;
    }

    private void setCoordinates(FoundItem foundItem, FoundItemRegisterRequest request) {
        if (Objects.nonNull(request.getLatitude()) && Objects.nonNull(request.getLongitude())) {
            Point coordinates = geometryFactory.createPoint(
                    new Coordinate(request.getLongitude(), request.getLatitude()));
            foundItem.setCoordinates(coordinates);
        }
    }

}

