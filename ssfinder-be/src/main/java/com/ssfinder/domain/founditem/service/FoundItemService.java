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
import com.ssfinder.global.common.service.HadoopService;
import com.ssfinder.global.common.service.ImageProcessingService;
import com.ssfinder.global.common.service.S3Service;
import com.ssfinder.global.util.CustomMultipartFile;
import net.coobird.thumbnailator.Thumbnails;
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
import org.springframework.web.multipart.MultipartFile;
import org.springframework.data.elasticsearch.core.ElasticsearchOperations;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.core.geo.GeoPoint;
import org.springframework.data.elasticsearch.core.query.Criteria;
import org.springframework.data.elasticsearch.core.query.CriteriaQuery;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
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
    private final S3Service s3Service;
    private final ImageProcessingService imageProcessingService;
    private final HadoopService hadoopService;
    private final ElasticsearchService elasticsearchService;
    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);
    private final ElasticsearchOperations elasticsearchOperations;
    private final FoundItemDocumentMapper foundItemDocumentMapper;

    @Transactional
    public FoundItemDocument registerFoundItem(int userId, FoundItemRegisterRequest requestDTO) {

        User user = userService.findUserById(userId);

        ItemCategory itemCategory = itemCategoryRepository.findById(requestDTO.getItemCategoryId())
                .orElseThrow(() -> new CustomException(ErrorCode.CATEGORY_NOT_FOUND));

        FoundItem foundItem = new FoundItem();
        foundItem.setUser(user);
        foundItem.setItemCategory(itemCategory);
        foundItem.setName(requestDTO.getName());
        foundItem.setFoundAt(requestDTO.getFoundAt());
        foundItem.setLocation(requestDTO.getLocation());
        foundItem.setColor(requestDTO.getColor());
        foundItem.setStoredAt(requestDTO.getStoredAt());

        if (Objects.nonNull(requestDTO.getStatus())) {
            foundItem.setStatus(FoundItemStatus.valueOf(requestDTO.getStatus()));
        }

        if(Objects.nonNull(requestDTO.getLatitude()) && Objects.nonNull(requestDTO.getLongitude())) {
            Point coordinates = geometryFactory.createPoint(new Coordinate(requestDTO.getLongitude(), requestDTO.getLatitude()));
            foundItem.setCoordinates(coordinates);
        }

        String imageUrl = null;
        String hdfsImagePath = null;
        byte[] processedImageBytes = null;
        MultipartFile originalImage = requestDTO.getImage();

        try {
            if (Objects.nonNull(originalImage) && !originalImage.isEmpty()) {
                String originalFilename = originalImage.getOriginalFilename();
                log.info("원본 이미지 파일명: {}", originalFilename);

                // 다양한 이미지 형식을 받기 위한 전략적 접근
                try {
                    // 1. 정상적인 이미지 전처리 시도
                    processedImageBytes = imageProcessingService.processImage(originalImage);
                    log.info("기본 이미지 전처리 성공: {}", originalFilename);
                } catch (Exception e) {
                    log.error("기본 이미지 전처리 실패, 대체 방법 시도: {}", e.getMessage());

                    try {
                        // 2. 전처리 실패 시 Thumbnailator 직접 사용 시도
                        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
                        Thumbnails.of(originalImage.getInputStream())
                                .size(512, 512)  // 기본 리사이즈 크기
                                .outputFormat("jpg")
                                .outputQuality(0.9)  // 90% 품질
                                .toOutputStream(outputStream);
                        processedImageBytes = outputStream.toByteArray();
                        log.info("Thumbnailator 직접 변환 성공");
                    } catch (Exception e2) {
                        log.error("Thumbnailator 변환 실패, 마지막 시도: {}", e2.getMessage());

                        try {
                            // 3. 마지막 시도: 원본 이미지 바이트 사용
                            processedImageBytes = originalImage.getBytes();
                            log.info("원본 이미지 바이트 사용으로 진행");
                        } catch (IOException ioe) {
                            log.error("원본 이미지 바이트 읽기 실패, 이미지 저장 불가: {}", ioe.getMessage());
                        }
                    }
                }

                // 처리된 이미지가 있을 경우 저장 진행
                if (processedImageBytes != null) {
                    // 파일명을 항상 jpg로 변환
                    if (originalFilename != null) {
                        int dotIndex = originalFilename.lastIndexOf('.');
                        if (dotIndex > 0) {
                            originalFilename = originalFilename.substring(0, dotIndex) + ".jpg";
                        } else {
                            originalFilename = originalFilename + ".jpg";
                        }
                    } else {
                        originalFilename = "image_" + System.currentTimeMillis() + ".jpg";
                    }

                    String contentType = "image/jpeg";

                    CustomMultipartFile processedImageFile = new CustomMultipartFile(
                            processedImageBytes,
                            originalFilename,
                            contentType
                    );

                    // S3에 이미지 업로드
                    try {
                        imageUrl = s3Service.uploadFile(processedImageFile, "found");
                        foundItem.setImage(imageUrl);
                        log.info("전처리된 이미지를 S3에 업로드 완료: {}", imageUrl);
                    } catch (Exception e) {
                        log.error("S3 이미지 업로드 실패: {}", e.getMessage());
                    }
                }
            }
        } catch (Exception e) {
            log.error("이미지 처리 중 예상치 못한 오류 발생: {}", e.getMessage(), e);
        }

        LocalDateTime now = LocalDateTime.now();
        foundItem.setCreatedAt(now);
        foundItem.setUpdatedAt(now);

        // MySQL DB에 저장
        FoundItem savedItem = foundItemRepository.save(foundItem);

        FoundItemDocument document = FoundItemDocument.builder()
                .mysqlId(String.valueOf(savedItem.getId()))
                .userId(savedItem.getUser() != null ? String.valueOf(savedItem.getUser().getId()) : null)
                // 아이템 카테고리 매핑: 부모 카테고리가 있으면 major는 부모, minor는 현재 카테고리, 없으면 major만 설정
                .categoryMajor(savedItem.getItemCategory() != null
                        ? (savedItem.getItemCategory().getItemCategory() != null
                        ? savedItem.getItemCategory().getItemCategory().getName()
                        : savedItem.getItemCategory().getName())
                        : null)
                .categoryMinor(savedItem.getItemCategory() != null
                        ? (savedItem.getItemCategory().getItemCategory() != null
                        ? savedItem.getItemCategory().getName()
                        : null)
                        : null)
                .name(savedItem.getName())
                .foundAt(savedItem.getFoundAt() != null ? savedItem.getFoundAt().toString() : null)
                .color(savedItem.getColor())
                .status(savedItem.getStatus() != null ? savedItem.getStatus().toString() : null)
                .location(savedItem.getLocation())
                .phone(savedItem.getPhone())
                .detail(savedItem.getDetail())
                .image(savedItem.getImage())
                .storedAt(savedItem.getStoredAt())
                .managementId(savedItem.getManagementId())
                .latitude(savedItem.getCoordinates() != null ? savedItem.getCoordinates().getY() : null)
                .longitude(savedItem.getCoordinates() != null ? savedItem.getCoordinates().getX() : null)
                .locationGeo(savedItem.getCoordinates() != null
                        ? new org.springframework.data.elasticsearch.core.geo.GeoPoint(
                        savedItem.getCoordinates().getY(),
                        savedItem.getCoordinates().getX())
                        : null)
                .build();
        foundItemDocumentRepository.save(document);

        return document;
    }


    @Transactional(readOnly = true)
    public FoundItemDocumentDetailResponse getFoundItemDetail(int foundId) {
//        FoundItem foundItem = foundItemRepository.findById(foundId)
//                .orElseThrow(() -> new CustomException(ErrorCode.FOUND_ITEM_NOT_FOUND));
        FoundItemDocument itemRes = foundItemDocumentRepository.findById(String.valueOf(foundId)).get();

        FoundItemDocumentDetailResponse response = new FoundItemDocumentDetailResponse();
        response.setId(itemRes.getId());
        if (Objects.nonNull(itemRes.getUserId())){
            response.setUserId(itemRes.getUserId());
        }

        boolean type = true;
        if (Objects.nonNull(itemRes.getManagementId())) {
            type = false;
        }

        response.setName(itemRes.getName());
        response.setFoundAt(LocalDateTime.parse(itemRes.getFoundAt(), DateTimeFormatter.ISO_LOCAL_DATE_TIME).toLocalDate());
        response.setColor(itemRes.getColor());
        response.setLocation(itemRes.getLocation());
        response.setStatus(itemRes.getStatus().toString());
        response.setDetail(itemRes.getDetail());
        response.setImage(itemRes.getImage());
        response.setStoredAt(itemRes.getStoredAt());
        response.setLatitude(itemRes.getLatitude());
        response.setLongitude(itemRes.getLongitude());
        response.setPhone(itemRes.getPhone());

        response.setMajorCategory(itemRes.getCategoryMajor());
        response.setMinorCategory(itemRes.getCategoryMinor());
        response.setType(type);

        return response;
    }

//    @Transactional
//    public FoundItemUpdateResponse updateFoundItem(int userId, int foundId, FoundItemUpdateRequest updateRequest) throws IOException {
//
//        FoundItem foundItem = foundItemRepository.findById(foundId)
//                .orElseThrow(() -> new CustomException(ErrorCode.FOUND_ITEM_NOT_FOUND));
//
//        if (!foundItem.getUser().getId().equals(userId)) {
//            throw new CustomException(ErrorCode.FOUND_ITEM_ACCESS_DENIED);
//        }
//
//        foundItemMapper.updateFoundItemFromRequest(updateRequest, foundItem);
//
//        if(Objects.nonNull(updateRequest.getLatitude()) && Objects.nonNull(updateRequest.getLongitude())) {
//            Point coordinates = geometryFactory.createPoint(new Coordinate(updateRequest.getLongitude(), updateRequest.getLatitude()));
//            foundItem.setCoordinates(coordinates);
//        }  else {
//            throw new CustomException(ErrorCode.INVALID_INPUT_VALUE);
//        }
//
//        String imageUrl = foundItem.getImage();
//        if(Objects.nonNull(updateRequest.getImage()) && !updateRequest.getImage().isEmpty()){
//            if (Objects.nonNull(imageUrl)){
//                imageUrl = s3Service.updateFile(imageUrl, updateRequest.getImage());
//            } else {
//                imageUrl = s3Service.uploadFile(updateRequest.getImage(), "found");
//            }
//        }
//
//        foundItem.setImage(imageUrl);
//
//        foundItem.setUpdatedAt(LocalDateTime.now());
//
//        return foundItemMapper.toUpdateResponse(foundItem);
//    }

//    @Transactional
//    public void deleteFoundItem(int userId, int foundId) {
//
//        FoundItem foundItem = foundItemRepository.findById(foundId)
//                .orElseThrow(() -> new CustomException(ErrorCode.FOUND_ITEM_NOT_FOUND));
//
//        if(foundItem.getUser().getId()!=userId) {
//            throw new CustomException(ErrorCode.FOUND_ITEM_ACCESS_DENIED);
//        }
//        if (Objects.nonNull(foundItem.getImage())) {
//            s3Service.deleteFile(foundItem.getImage());
//        }
//        foundItemRepository.delete(foundItem);
//    }

    @Transactional
    public FoundItemDocumentDetailResponse updateFoundItemStatus(int userId, int foundId, FoundItemStatusUpdateRequest request) {

        FoundItem foundItem = foundItemRepository.findById(foundId)
                .orElseThrow(() -> new CustomException(ErrorCode.FOUND_ITEM_NOT_FOUND));

        if (!foundItem.getUser().getId().equals(userId)) {
            throw new CustomException(ErrorCode.FOUND_ITEM_ACCESS_DENIED);
        }

        foundItem.setStatus(FoundItemStatus.valueOf(request.getStatus()));
        foundItem.setUpdatedAt(LocalDateTime.now());

        FoundItemDocument document = foundItemDocumentRepository.findById(String.valueOf(foundItem.getId())).get();
        document.setStatus(String.valueOf(FoundItemStatus.valueOf(request.getStatus())));
        foundItemDocumentRepository.save(document);

        boolean type = true;
        if (Objects.nonNull(document.getManagementId())) {
            type = false;
        }

        FoundItemDocumentDetailResponse response = new FoundItemDocumentDetailResponse();
        response.setId(document.getId());
        response.setUserId(document.getId());
        response.setMajorCategory(document.getCategoryMajor());
        response.setMinorCategory(document.getCategoryMinor());
        response.setName(document.getName());
        response.setFoundAt(LocalDate.parse(document.getFoundAt()));
        response.setLocation(document.getLocation());
        response.setColor(document.getColor());
        response.setStatus(String.valueOf(FoundItemStatus.valueOf(request.getStatus())));
        response.setDetail(document.getDetail());
        response.setImage(document.getImage());
        response.setStoredAt(document.getStoredAt());
        response.setCreatedAt(foundItem.getCreatedAt());
        response.setUpdatedAt(foundItem.getUpdatedAt());
        response.setLatitude(document.getLatitude());
        response.setLongitude(document.getLongitude());
        response.setPhone(document.getPhone());
        response.setType(type);

        return response;
    }

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
            e.printStackTrace();
            return new PageImpl<>(Collections.emptyList(), pageable, 0);
        }
    }

    @Transactional(readOnly = true)
    public List<FoundItemDocumentDetailResponse> getFoundItemsByViewport(FoundItemViewportRequest viewportRequest) {
        // latitude 범위 조건 (예: minLatitude ~ maxLatitude)
        Criteria latCriteria = new Criteria("location_geo.lat")
                .between(viewportRequest.getMinLatitude(), viewportRequest.getMaxLatitude());

        // longitude 범위 조건 (예: minLongitude ~ maxLongitude)
        Criteria lonCriteria = new Criteria("location_geo.lon")
                .between(viewportRequest.getMinLongitude(), viewportRequest.getMaxLongitude());

        // 두 조건을 AND 결합
        Criteria criteria = latCriteria.and(lonCriteria);
        CriteriaQuery query = new CriteriaQuery(criteria);

        // 쿼리 실행
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

            // foundAt 문자열의 처음 10자를 LocalDate로 파싱
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

        // id는 mysql_id 값을 사용 (Integer로 변환)
        response.setId(document.getMysqlId() != null ? Integer.valueOf(document.getMysqlId()) : null);

        // userId도 Integer로 변환
        response.setUserId(document.getUserId() != null ? Integer.valueOf(document.getUserId()) : null);

        response.setMajorCategory(document.getCategoryMajor());
        response.setMinorCategory(document.getCategoryMinor());
        response.setName(document.getName());

        // foundAt을 LocalDateTime으로 파싱 후 LocalDate로 변환
        response.setFoundAt(document.getFoundAt() != null
                ? LocalDateTime.parse(document.getFoundAt(), DateTimeFormatter.ISO_LOCAL_DATE_TIME).toLocalDate()
                : null);

        response.setLocation(document.getLocation());
        response.setColor(document.getColor());
        response.setStatus(document.getStatus());
        response.setDetail(document.getDetail());
        response.setImage(document.getImage());
        response.setStoredAt(document.getStoredAt());

        // 생성일/수정일 정보가 Document에 없어 현재는 임시로 현 시점으로 설정
        response.setCreatedAt(LocalDateTime.now());
        response.setUpdatedAt(LocalDateTime.now());

        response.setLatitude(document.getLatitude());
        response.setLongitude(document.getLongitude());

        return response;
    }

}

