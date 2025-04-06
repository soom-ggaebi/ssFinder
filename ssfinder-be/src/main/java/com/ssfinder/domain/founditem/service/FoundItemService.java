package com.ssfinder.domain.founditem.service;

import com.ssfinder.domain.founditem.dto.mapper.FoundItemDocumentMapper;
import com.ssfinder.domain.founditem.dto.mapper.FoundItemMapper;
import com.ssfinder.domain.founditem.dto.request.*;
import com.ssfinder.domain.founditem.dto.response.*;
import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.founditem.entity.FoundItemDocument;
import com.ssfinder.domain.founditem.entity.FoundItemStatus;
import com.ssfinder.domain.founditem.repository.FoundItemDocumentRepository;
import com.ssfinder.domain.founditem.repository.FoundItemRepository;
import com.ssfinder.domain.itemcategory.entity.ItemCategory;
import com.ssfinder.domain.itemcategory.repository.ItemCategoryRepository;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.service.UserService;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import com.ssfinder.global.common.service.*;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.data.domain.*;
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

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
 * 2025-03-31          nature1216            findFoundItemById 메소드 추가<br>
 * 2025-04-04          leeyj                 일라스틱서치로 crud 변경<br>
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
    private final ElasticsearchAsyncService elasticsearchAsyncService;
    private final FoundItemBookmarkService foundItemBookmarkService;
    private final FoundItemDocumentMapper foundItemDocumentMapper;
    private final ImageHandler imageHandler;
    private final S3Service s3Service;
    private final FoundItemElasticsearchQueryService elasticsearchQueryService;

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
    public FoundItemDocumentDetailResponse getFoundItemDetail(Integer userId, int foundId) {
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
    public FoundItemUpdateResponse updateFoundItem(int userId, int foundId, FoundItemUpdateRequest request) {
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
            Point coordinates = geometryFactory.createPoint(new Coordinate(request.getLongitude(), request.getLatitude()));
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
        if (!foundItem.getUser().getId().equals(userId)) {
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
            foundItemBookmarkService.deleteAllBookmarksByFoundItemId(foundId);
        } catch (Exception e) {
            log.error("북마크 삭제 실패 (계속 진행): FoundItemId={}, 오류={}", foundId, e.getMessage());
        }
        foundItemRepository.delete(foundItem);
        elasticsearchAsyncService.deleteFoundItemFromElasticsearch(String.valueOf(foundId));
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

    // 내 습득물 조회 (Elasticsearch 검색은 별도 QueryService로 위임)
    @Transactional(readOnly = true)
    public Page<FoundItemDetailResponse> getMyFoundItems(int userId, Pageable pageable) {
        return elasticsearchQueryService.getMyFoundItems(userId, pageable);
    }

    // 찾기
    @Transactional(readOnly = true)
    public FoundItem findFoundItemById(Integer foundItemId) {
        return foundItemRepository.findById(foundItemId)
                .orElseThrow(() -> new CustomException(ErrorCode.FOUND_ITEM_NOT_FOUND));
    }

    // 좌표 설정
    private void setCoordinates(FoundItem foundItem, FoundItemRegisterRequest request) {
        if (Objects.nonNull(request.getLatitude()) && Objects.nonNull(request.getLongitude())) {
            Point coordinates = geometryFactory.createPoint(new Coordinate(request.getLongitude(), request.getLatitude()));
            foundItem.setCoordinates(coordinates);
        }
    }

    public List<FoundItem> getStoredItemsFoundDaysAgo(int daysAgo) {
        return foundItemRepository.findByFoundAtAndStatus(LocalDate.now().minusDays(daysAgo), FoundItemStatus.STORED);
    }
}