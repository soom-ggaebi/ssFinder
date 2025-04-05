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
import jakarta.validation.Valid;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.data.domain.*;
import org.springframework.data.elasticsearch.core.query.FetchSourceFilter;
import org.springframework.data.elasticsearch.core.query.StringQuery;
import org.springframework.scheduling.annotation.Async;
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
import java.util.concurrent.CompletableFuture;
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

    // 내 습득물 조회 -- 변경할거임.
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
    public SearchAfterPageResponse<FoundItemDocumentDetailResponse> getFoundItemsByViewport(
            FoundItemViewportRequest viewportRequest, Object[] searchAfter, int pageSize) {

        Criteria latCriteria = new Criteria("location_geo.lat")
                .between(viewportRequest.getMinLatitude(), viewportRequest.getMaxLatitude());
        Criteria lonCriteria = new Criteria("location_geo.lon")
                .between(viewportRequest.getMinLongitude(), viewportRequest.getMaxLongitude());
        Criteria criteria = latCriteria.and(lonCriteria);

        CriteriaQuery query = new CriteriaQuery(criteria);

        query.addSort(Sort.by(Sort.Order.asc("location_geo.lat"), Sort.Order.asc("location_geo.lon")));

        query.setPageable(PageRequest.of(0, pageSize));

        if (searchAfter != null) {
            query.setSearchAfter(Arrays.asList(searchAfter));
        }

        SearchHits<FoundItemDocument> searchHits = elasticsearchOperations.search(query, FoundItemDocument.class);

        List<FoundItemDocumentDetailResponse> responses = searchHits.getSearchHits().stream().map(hit -> {
            FoundItemDocument doc = hit.getContent();
            FoundItemDocumentDetailResponse response = new FoundItemDocumentDetailResponse();

            boolean type = (doc.getManagementId() == null);
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

        Object[] nextSearchAfterToken = null;
        if (!searchHits.getSearchHits().isEmpty()) {
            SearchHit<FoundItemDocument> lastHit = searchHits.getSearchHits()
                    .get(searchHits.getSearchHits().size() - 1);
            nextSearchAfterToken = lastHit.getSortValues().toArray();
        }

        return new SearchAfterPageResponse<>(responses, nextSearchAfterToken);
    }

    // 뷰포트 기준 모든 좌표 조회
    @Async("elasticsearchExecutor")
    @Transactional(readOnly = true)
    public CompletableFuture<List<FoundItemClusterResponse>> getCoordinatesInViewportForClusteringAsync(
            @Valid FoundItemViewportRequest request) {

        List<FoundItemClusterResponse> allResponses = new ArrayList<>();
        int batchSize = 10000;
        int batchCount = 0;
        List<Object> searchAfterValues = null;
        boolean hasMoreData = true;

        while (hasMoreData) {

            String queryJson = String.format(
                    "{\"bool\":{\"filter\":{\"geo_bounding_box\":{\"location_geo\":{" +
                            "\"top_left\":{\"lat\":%f,\"lon\":%f}," +
                            "\"bottom_right\":{\"lat\":%f,\"lon\":%f}" +
                            "}}}}}",
                    request.getMaxLatitude(), request.getMinLongitude(),
                    request.getMinLatitude(), request.getMaxLongitude()
            );


            StringQuery query = new StringQuery(queryJson);
            query.setPageable(PageRequest.of(0, batchSize, Sort.by(Sort.Direction.ASC, "mysql_id")));

            query.addSourceFilter(FetchSourceFilter.of(new String[]{"mysql_id", "latitude", "longitude"}, null));

            if (searchAfterValues != null) {
                query.setSearchAfter(searchAfterValues);
            }

            SearchHits<FoundItemDocument> searchHits = elasticsearchOperations.search(query, FoundItemDocument.class);

            if (!searchHits.hasSearchHits()) {
                hasMoreData = false;
                continue;
            }

            int processedCount = 0;

            for (SearchHit<FoundItemDocument> hit : searchHits.getSearchHits()) {
                FoundItemDocument doc = hit.getContent();
                if (doc.getLatitude() == 0.0 && doc.getLongitude() == 0.0) {
                    continue;
                }
                processHit(hit, allResponses);
                processedCount++;
            }

            batchCount++;
            log.info("배치 #{}: {}개 항목 처리, 현재까지 총 {}개", batchCount, processedCount, allResponses.size());

            if (!searchHits.getSearchHits().isEmpty()) {
                searchAfterValues = searchHits.getSearchHits()
                        .get(searchHits.getSearchHits().size() - 1)
                        .getSortValues();
            }

            if (searchHits.getSearchHits().size() < batchSize) {
                hasMoreData = false;
            }

            if (batchCount >= 100) {
                log.warn("최대 배치 수 도달 ({}), 조회 중단", batchCount);
                break;
            }
        }

        log.info("총 {}개 항목 조회 완료 (search_after 사용, {} 배치)", allResponses.size(), batchCount);
        return CompletableFuture.completedFuture(allResponses);
    }

    // 필터로 위도, 경도 조회
    @Async("elasticsearchExecutor")
    @Transactional(readOnly = true)
    public CompletableFuture<List<FoundItemClusterResponse>> getFilteredFoundItemsAsync(FoundItemFilterRequest request) {
        log.info("필터링 조회 시작: {}", request);
        List<FoundItemClusterResponse> allResponses = new ArrayList<>();
        int batchSize = 10000;
        int batchCount = 0;
        List<Object> searchAfterValues = null;
        boolean hasMoreData = true;

        StringBuilder mustFilters = new StringBuilder();
        mustFilters.append("[");

        mustFilters.append(String.format(
                "{\"geo_bounding_box\": {\"location_geo\": {\"top_left\": {\"lat\": %f, \"lon\": %f}, \"bottom_right\": {\"lat\": %f, \"lon\": %f}}}}",
                request.getMaxLatitude(), request.getMinLongitude(),
                request.getMinLatitude(), request.getMaxLongitude()
        ));

        if (request.getStatus() != null && !request.getStatus().equalsIgnoreCase("all")) {
            mustFilters.append(",");
            mustFilters.append(String.format("{\"term\": {\"status\": \"%s\"}}", request.getStatus()));
        }

        if (request.getType() != null && !request.getType().equalsIgnoreCase("전체")) {
            mustFilters.append(",");
            if (request.getType().equals("숨숨파인더")) {
                mustFilters.append("{\"bool\": {\"must_not\": {\"exists\": {\"field\": \"management_id\"}}}}");
            } else if (request.getType().equals("경찰")) {
                mustFilters.append("{\"exists\": {\"field\": \"management_id\"}}");
            }
        }

        if (request.getStoredAt() != null && !request.getStoredAt().isEmpty()) {
            mustFilters.append(",");
            mustFilters.append(String.format("{\"term\": {\"stored_at\": \"%s\"}}", request.getStoredAt()));
        }

        if (request.getFoundAt() != null) {
            mustFilters.append(",");
            mustFilters.append(String.format("{\"term\": {\"found_at\": \"%s\"}}", request.getFoundAt().toString()));
        }

        if (request.getMajorCategory() != null && !request.getMajorCategory().isEmpty()) {
            mustFilters.append(",");
            mustFilters.append(String.format("{\"term\": {\"category_major\": \"%s\"}}", request.getMajorCategory()));
        }

        if (request.getMinorCategory() != null && !request.getMinorCategory().isEmpty()) {
            mustFilters.append(",");
            mustFilters.append(String.format("{\"term\": {\"category_minor\": \"%s\"}}", request.getMinorCategory()));
        }

        if (request.getColor() != null && !request.getColor().isEmpty()) {
            mustFilters.append(",");
            mustFilters.append(String.format("{\"term\": {\"color\": \"%s\"}}", request.getColor()));
        }
        mustFilters.append("]");

        String finalQueryJson = String.format(
                "{\"bool\": {\"must\": %s}}",
                mustFilters.toString()
        );

        log.info("최종 쿼리 JSON: {}", finalQueryJson);

        while (hasMoreData) {
            StringQuery query = new StringQuery(finalQueryJson);
            query.setPageable(PageRequest.of(0, batchSize, Sort.by(Sort.Direction.ASC, "mysql_id")));
            query.addSourceFilter(FetchSourceFilter.of(new String[]{"mysql_id", "latitude", "longitude"}, null));

            if (searchAfterValues != null) {
                query.setSearchAfter(searchAfterValues);
            }

            SearchHits<FoundItemDocument> searchHits = elasticsearchOperations.search(query, FoundItemDocument.class);

            if (!searchHits.hasSearchHits()) {
                hasMoreData = false;
                break;
            }

            int processedCount = 0;
            for (SearchHit<FoundItemDocument> hit : searchHits.getSearchHits()) {
                processHit(hit, allResponses);
                processedCount++;
            }

            batchCount++;
            log.info("배치 #{}: {}개 항목 처리, 현재까지 총 {}개", batchCount, processedCount, allResponses.size());

            if (!searchHits.getSearchHits().isEmpty()) {
                searchAfterValues = searchHits.getSearchHits()
                        .get(searchHits.getSearchHits().size() - 1)
                        .getSortValues();
            }

            if (searchHits.getSearchHits().size() < batchSize) {
                hasMoreData = false;
            }

            if (batchCount >= 100) {
                log.warn("최대 배치 수 도달 ({}), 조회 중단", batchCount);
                break;
            }
        }

        log.info("총 {}개 항목 조회 완료 (search_after 사용, {} 배치)", allResponses.size(), batchCount);
        return CompletableFuture.completedFuture(allResponses);
    }

    // 클러스트 기준 리스트 조회
    @Transactional(readOnly = true)
    public Page<FoundItemSummaryResponse> getClusterDetailItems(
            Integer userId, List<Integer> ids, Pageable pageable) {

        try {
            int totalSize = ids.size();
            int pageSize = pageable.getPageSize();
            int pageNumber = pageable.getPageNumber();
            int startIndex = pageNumber * pageSize;
            int endIndex = Math.min(startIndex + pageSize, totalSize);

            if (startIndex >= totalSize) {
                return new PageImpl<>(Collections.emptyList(), pageable, totalSize);
            }

            List<Integer> pageIds = ids.subList(startIndex, endIndex);
            List<String> idStrings = pageIds.stream()
                    .map(String::valueOf)
                    .collect(Collectors.toList());

            Criteria criteria = new Criteria("mysql_id").in(idStrings);
            CriteriaQuery query = new CriteriaQuery(criteria);

            if (pageable.getSort().isSorted()) {
                query.addSort(pageable.getSort());
            }

            query.setPageable(PageRequest.of(0, pageSize));

            SearchHits<FoundItemDocument> searchHits = elasticsearchOperations.search(
                    query, FoundItemDocument.class);

            Map<String, FoundItemDocument> docMap = new HashMap<>();
            for (SearchHit<FoundItemDocument> hit : searchHits.getSearchHits()) {
                FoundItemDocument doc = hit.getContent();
                if (doc.getMysqlId() != null) {
                    docMap.put(doc.getMysqlId(), doc);
                }
            }

            List<FoundItemSummaryResponse> content = new ArrayList<>();
            for (String idString : idStrings) {
                FoundItemDocument doc = docMap.get(idString);
                if (doc != null) {
                    FoundItemSummaryResponse response = convertToSummaryResponse(doc);
                    content.add(response);
                }
            }

            if (userId != null) {
                setBookmarkInfo(userId, content);
            } else {
                content.forEach(item -> item.setBookmarked(false));
            }

            Page<FoundItemSummaryResponse> result = new PageImpl<>(
                    content, pageable, totalSize);

            log.info("클러스터 상세 정보 조회 완료 - 페이지 항목: {}/{}, 총 항목: {}",
                    content.size(), pageSize, totalSize);

            return result;

        } catch (Exception e) {
            log.error("클러스터 상세 정보 조회 중 오류 발생: {}", e.getMessage(), e);
            return new PageImpl<>(Collections.emptyList(), pageable, 0);
        }
    }

    public List<FoundItem> getStoredItemsFoundDaysAgo(int daysAgo) {
        return foundItemRepository.findByFoundAtAndStatus(LocalDate.now().minusDays(daysAgo), FoundItemStatus.STORED);
    }

    // 뷰포트 기준 리스트 조회
    @Transactional(readOnly = true)
    public Page<FoundItemSummaryResponse> getPagedFoundItemsInViewport(
            Integer userId, FoundItemViewportRequest request, Pageable pageable) {

        String finalQueryJson = String.format(
                "{\"bool\": {\"filter\": {\"geo_bounding_box\": {\"location_geo\": {" +
                        "\"top_left\": {\"lat\": %f, \"lon\": %f}, " +
                        "\"bottom_right\": {\"lat\": %f, \"lon\": %f}" +
                        "}}}}}",
                request.getMaxLatitude(), request.getMinLongitude(),
                request.getMinLatitude(), request.getMaxLongitude()
        );


        StringQuery query = new StringQuery(finalQueryJson);
        query.setPageable(pageable);

        query.addSourceFilter(FetchSourceFilter.of(
                new String[]{"mysql_id", "image", "category_major", "category_minor", "name", "location", "stored_at", "created_at", "management_id"},
                null));

        SearchHits<FoundItemDocument> searchHits = elasticsearchOperations.search(query, FoundItemDocument.class);

        List<FoundItemSummaryResponse> content = searchHits.getSearchHits().stream()
                .map(hit -> convertToSummaryResponse(hit.getContent()))
                .collect(Collectors.toList());

        if (userId != null) {
            setBookmarkInfo(userId, content);
        } else {
            content.forEach(item -> item.setBookmarked(false));
        }

        return new PageImpl<>(content, pageable, searchHits.getTotalHits());
    }

    // 필터링 된 리스트
    @Transactional(readOnly = true)
    public Page<FoundItemSummaryResponse> getFilteredFoundItemsForDetail(
            Integer userId, FoundItemFilterRequest request, Pageable pageable) {

        StringBuilder mustFilters = new StringBuilder();
        mustFilters.append("[");

        mustFilters.append(String.format(
                "{\"geo_bounding_box\": {\"location_geo\": {\"top_left\": {\"lat\": %f, \"lon\": %f}, \"bottom_right\": {\"lat\": %f, \"lon\": %f}}}}",
                request.getMaxLatitude(), request.getMinLongitude(),
                request.getMinLatitude(), request.getMaxLongitude()
        ));

        if (request.getStatus() != null && !request.getStatus().equalsIgnoreCase("all")) {
            mustFilters.append(",{\"term\": {\"status\": \"").append(request.getStatus()).append("\"}}");
        }

        if (request.getType() != null && !request.getType().equalsIgnoreCase("전체")) {
            mustFilters.append(",");
            if (request.getType().equals("숨숨파인더")) {
                mustFilters.append("{\"bool\": {\"must_not\": {\"exists\": {\"field\": \"management_id\"}}}}");
            } else if (request.getType().equals("경찰")) {
                mustFilters.append("{\"exists\": {\"field\": \"management_id\"}}");
            }
        }

        if (request.getStoredAt() != null && !request.getStoredAt().isEmpty()) {
            mustFilters.append(",{\"term\": {\"stored_at\": \"").append(request.getStoredAt()).append("\"}}");
        }

        if (request.getFoundAt() != null) {
            mustFilters.append(",{\"term\": {\"found_at\": \"").append(request.getFoundAt().toString()).append("\"}}");
        }

        if (request.getMajorCategory() != null && !request.getMajorCategory().isEmpty()) {
            mustFilters.append(",{\"term\": {\"category_major\": \"").append(request.getMajorCategory()).append("\"}}");
        }

        if (request.getMinorCategory() != null && !request.getMinorCategory().isEmpty()) {
            mustFilters.append(",{\"term\": {\"category_minor\": \"").append(request.getMinorCategory()).append("\"}}");
        }

        if (request.getColor() != null && !request.getColor().isEmpty()) {
            mustFilters.append(",{\"term\": {\"color\": \"").append(request.getColor()).append("\"}}");
        }
        mustFilters.append("]");

        String finalQueryJson = String.format(
                "{\"bool\": {\"must\": %s}}",
                mustFilters.toString()
        );

        StringQuery query = new StringQuery(finalQueryJson);
        query.setPageable(pageable);
        query.addSourceFilter(FetchSourceFilter.of(
                new String[]{"mysql_id", "image", "category_major", "category_minor", "name", "location", "stored_at", "created_at", "management_id"},
                null));

        SearchHits<FoundItemDocument> searchHits = elasticsearchOperations.search(query, FoundItemDocument.class);

        List<FoundItemSummaryResponse> content = searchHits.getSearchHits().stream()
                .map(hit -> convertToSummaryResponse(hit.getContent()))
                .collect(Collectors.toList());

        if (userId != null) {
            setBookmarkInfo(userId, content);
        } else {
            content.forEach(item -> item.setBookmarked(false));
        }

        return new PageImpl<>(content, pageable, searchHits.getTotalHits());
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

    // 위도, 경도 변환
    private void setCoordinates(FoundItem foundItem, FoundItemRegisterRequest request) {
        if (Objects.nonNull(request.getLatitude()) && Objects.nonNull(request.getLongitude())) {
            Point coordinates = geometryFactory.createPoint(
                    new Coordinate(request.getLongitude(), request.getLatitude()));
            foundItem.setCoordinates(coordinates);
        }
    }

    // 뷰포트 기준 위도, 경도 전체 조회
    private void processHit(SearchHit<FoundItemDocument> hit, List<FoundItemClusterResponse> responses) {
        FoundItemDocument doc = hit.getContent();
        FoundItemClusterResponse response = new FoundItemClusterResponse();
        response.setId(Integer.valueOf(doc.getMysqlId()));
        response.setLatitude(doc.getLatitude());
        response.setLongitude(doc.getLongitude());
        responses.add(response);
    }

    // 사용자 북마크 정보 조회
    private void setBookmarkInfo(Integer userId, List<FoundItemSummaryResponse> items) {
        List<Integer> itemIds = items.stream()
                .map(FoundItemSummaryResponse::getId)
                .collect(Collectors.toList());

        if (itemIds.isEmpty()) {
            return;
        }

        try {
            List<Integer> bookmarkedIds = foundItemBookmarkService.getBookmarkedItemIdsByUser(userId);

            for (FoundItemSummaryResponse item : items) {
                boolean isBookmarked = bookmarkedIds.contains(item.getId());
                item.setBookmarked(isBookmarked);
            }

        } catch (Exception e) {
            log.error("북마크 정보 조회 중 오류: {}", e.getMessage());
            items.forEach(item -> item.setBookmarked(false));
        }
    }

    // FoundItemSummaryResponse 변환
    private FoundItemSummaryResponse convertToSummaryResponse(FoundItemDocument doc) {
        FoundItemSummaryResponse response = new FoundItemSummaryResponse();

        response.setId(doc.getMysqlId() != null ? Integer.valueOf(doc.getMysqlId()) : null);

        response.setImage(doc.getImage());
        response.setMajorCategory(doc.getCategoryMajor());
        response.setMinorCategory(doc.getCategoryMinor());
        response.setName(doc.getName());
        response.setLocation(doc.getLocation());

        response.setType(doc.getManagementId() != null ? "경찰청" : "숨숨파인더");

        if (doc.getStoredAt() != null) {
            response.setStoredAt(doc.getStoredAt());
        }

        if (doc.getCreatedAt() != null) {
            try {
                response.setCreatedAt(LocalDateTime.parse(doc.getCreatedAt()));
            } catch (Exception e) {
                response.setCreatedAt(LocalDateTime.now());
            }
        } else {
            response.setCreatedAt(LocalDateTime.now());
        }

        response.setBookmarked(false);

        return response;
    }

    @Transactional(readOnly = true)
    public FoundItem findFoundItemById(Integer foundItemId) {
        return foundItemRepository.findById(foundItemId)
                .orElseThrow(() -> new CustomException(ErrorCode.FOUND_ITEM_NOT_FOUND));
    }

}