package com.ssfinder.domain.founditem.service;

import com.ssfinder.domain.founditem.dto.mapper.FoundItemMapper;
import com.ssfinder.domain.founditem.dto.request.FoundItemRegisterRequest;
import com.ssfinder.domain.founditem.dto.request.FoundItemStatusUpdateRequest;
import com.ssfinder.domain.founditem.dto.request.FoundItemUpdateRequest;
import com.ssfinder.domain.founditem.dto.request.FoundItemViewportRequest;
import com.ssfinder.domain.founditem.dto.response.FoundItemDetailResponse;
import com.ssfinder.domain.founditem.dto.response.FoundItemRegisterResponse;
import com.ssfinder.domain.founditem.dto.response.FoundItemStatusUpdateResponse;
import com.ssfinder.domain.founditem.dto.response.FoundItemUpdateResponse;
import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.founditem.entity.FoundItemStatus;
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
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDate;
import java.time.LocalDateTime;
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
    private final FoundItemMapper foundItemMapper;
    private final UserService userService;
    private final ItemCategoryRepository itemCategoryRepository;
    private final S3Service s3Service;
    private final ImageProcessingService imageProcessingService;
    private final HadoopService hadoopService;
    private final ElasticsearchService elasticsearchService;
    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    @Transactional
    public FoundItemRegisterResponse registerFoundItem(int userId, FoundItemRegisterRequest requestDTO) {

        FoundItem foundItem = foundItemMapper.toEntity(requestDTO);

        User user = userService.findUserById(userId);
        foundItem.setUser(user);

        ItemCategory itemCategory = itemCategoryRepository.findById(requestDTO.getItemCategoryId())
                .orElseThrow(() -> new CustomException(ErrorCode.CATEGORY_NOT_FOUND));
        foundItem.setItemCategory(itemCategory);

        if (Objects.nonNull(requestDTO.getStatus())) {
            foundItem.setStatus(FoundItemStatus.valueOf(requestDTO.getStatus()));
        }

        if(Objects.nonNull(requestDTO.getLatitude()) && Objects.nonNull(requestDTO.getLongitude())) {
            Point coordinates = geometryFactory.createPoint(new Coordinate(requestDTO.getLongitude(), requestDTO.getLatitude()));
            foundItem.setCoordinates(coordinates);
        }

        String imageUrl = null;
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

        // Hadoop과 Elasticsearch에 데이터 업로드
        String hdfsImagePath = null;

        try {
            // HDFS에 JPG 이미지 저장
            if (processedImageBytes != null) {
                try {
                    hdfsImagePath = hadoopService.getFoundImagePath(savedItem.getId().toString());
                    boolean success = hadoopService.saveImage(hdfsImagePath, processedImageBytes);
                    log.info("HDFS 이미지 저장 결과: {}, 경로: {}", success, hdfsImagePath);

                    if (!success) {
                        log.error("HDFS에 이미지 저장 실패");
                    }
                } catch (Exception e) {
                    log.error("HDFS 이미지 저장 중 오류 발생: {}", e.getMessage());
                }
            } else {
                log.info("저장할 이미지가 없습니다.");
            }
        } catch (Exception e) {
            log.error("HDFS 이미지 저장 시도 중 예상치 못한 오류: {}", e.getMessage());
        }

        try {
            // Elasticsearch에 문서 인덱싱
            elasticsearchService.indexFoundItem(savedItem, hdfsImagePath);
            log.info("Elasticsearch에 문서 인덱싱 요청 완료");
        } catch (Exception e) {
            log.error("Elasticsearch 인덱싱 중 오류 발생: {}", e.getMessage());
        }

        try {
            // CSV 저장에 필요한 데이터 준비
            List<Map<String, Object>> records = new ArrayList<>();
            Map<String, Object> record = new HashMap<>();

            // ElasticSearch 문서 형식과 동일하게 필드 설정 (null 체크 포함)
            record.put("mysql_id", savedItem.getId().toString());
            record.put("management_id", savedItem.getManagementId() != null ? savedItem.getManagementId() : "");
            record.put("name", savedItem.getName() != null ? savedItem.getName() : "");
            record.put("color", savedItem.getColor() != null ? savedItem.getColor() : "");
            record.put("found_at", savedItem.getFoundAt() != null ? savedItem.getFoundAt().toString() : "");
            record.put("status", savedItem.getStatus() != null ? savedItem.getStatus().name() : "");
            record.put("location", savedItem.getLocation() != null ? savedItem.getLocation() : "");
            record.put("stored_at", savedItem.getStoredAt() != null ? savedItem.getStoredAt() : "");
            record.put("phone", savedItem.getPhone() != null ? savedItem.getPhone() : "");
            record.put("detail", savedItem.getDetail() != null ? savedItem.getDetail() : "");
            record.put("image", imageUrl != null ? imageUrl : "");
            record.put("image_hdfs", hdfsImagePath != null ? hdfsImagePath : "");

            // 좌표 정보
            if (savedItem.getCoordinates() != null) {
                record.put("latitude", savedItem.getCoordinates().getY());
                record.put("longitude", savedItem.getCoordinates().getX());
            } else {
                record.put("latitude", 0.0);
                record.put("longitude", 0.0);
            }

            // 카테고리 정보 설정
            if (savedItem.getItemCategory() != null) {
                ItemCategory category = savedItem.getItemCategory();
                if (category.getItemCategory() == null) {
                    // 주 카테고리만 있는 경우
                    record.put("category_major", category.getName());
                    record.put("category_minor", "");
                } else {
                    // 주 카테고리와 부 카테고리가 모두 있는 경우
                    record.put("category_minor", category.getName());
                    record.put("category_major", category.getItemCategory().getName());
                }
            } else {
                record.put("category_major", "");
                record.put("category_minor", "");
            }

            record.put("created_at", savedItem.getCreatedAt().toString());
            records.add(record);

            // HDFS에 CSV 데이터 저장 - 헤더도 ElasticSearch 문서 필드와 동일하게 설정
            List<String> headers = Arrays.asList(
                    "mysql_id", "management_id", "name", "color", "found_at",
                    "status", "location", "stored_at", "phone", "detail",
                    "image", "image_hdfs", "latitude", "longitude",
                    "category_major", "category_minor", "created_at"
            );

            try {
                boolean csvSuccess = hadoopService.appendToCsv(hadoopService.getFoundCsvPath(), records, headers);
                log.info("HDFS CSV 저장 결과: {}", csvSuccess);
            } catch (Exception e) {
                log.error("HDFS CSV 저장 중 오류 발생: {}", e.getMessage());
            }
        } catch (Exception e) {
            log.error("HDFS/Elasticsearch 데이터 준비 중 오류 발생: {}", e.getMessage(), e);
        }

        return foundItemMapper.toResponse(savedItem);
    }


    @Transactional(readOnly = true)
    public FoundItemDetailResponse getFoundItemDetail(int foundId) {
        FoundItem foundItem = foundItemRepository.findById(foundId)
                .orElseThrow(() -> new CustomException(ErrorCode.FOUND_ITEM_NOT_FOUND));
        return foundItemMapper.toDetailResponse(foundItem);
    }

    @Transactional
    public FoundItemUpdateResponse updateFoundItem(Integer userId, Integer foundId, FoundItemUpdateRequest updateRequest) throws IOException {

        FoundItem foundItem = foundItemRepository.findById(foundId)
                .orElseThrow(() -> new CustomException(ErrorCode.FOUND_ITEM_NOT_FOUND));

        if (!foundItem.getUser().getId().equals(userId)) {
            throw new CustomException(ErrorCode.FOUND_ITEM_ACCESS_DENIED);
        }

        foundItemMapper.updateFoundItemFromRequest(updateRequest, foundItem);

        if(Objects.nonNull(updateRequest.getLatitude()) && Objects.nonNull(updateRequest.getLongitude())) {
            Point coordinates = geometryFactory.createPoint(new Coordinate(updateRequest.getLongitude(), updateRequest.getLatitude()));
            foundItem.setCoordinates(coordinates);
        }  else {
            throw new CustomException(ErrorCode.INVALID_INPUT_VALUE);
        }

        String imageUrl = foundItem.getImage();
        if(Objects.nonNull(updateRequest.getImage()) && !updateRequest.getImage().isEmpty()){
            if (Objects.nonNull(imageUrl)){
                imageUrl = s3Service.updateFile(imageUrl, updateRequest.getImage());
            } else {
                imageUrl = s3Service.uploadFile(updateRequest.getImage(), "found");
            }
        }

        foundItem.setImage(imageUrl);

        foundItem.setUpdatedAt(LocalDateTime.now());

        return foundItemMapper.toUpdateResponse(foundItem);
    }

    @Transactional
    public void deleteFoundItem(Integer userId, Integer foundId) {

        FoundItem foundItem = foundItemRepository.findById(foundId)
                .orElseThrow(() -> new CustomException(ErrorCode.FOUND_ITEM_NOT_FOUND));

        if(!foundItem.getUser().getId().equals(userId)) {
            throw new CustomException(ErrorCode.FOUND_ITEM_ACCESS_DENIED);
        }

        if (Objects.nonNull(foundItem.getImage())) {
            s3Service.deleteFile(foundItem.getImage());
        }

        foundItemRepository.delete(foundItem);
    }

    @Transactional
    public FoundItemStatusUpdateResponse updateFoundItemStatus(int userId, Integer foundId, FoundItemStatusUpdateRequest request) {

        FoundItem foundItem = foundItemRepository.findById(foundId)
                .orElseThrow(() -> new CustomException(ErrorCode.FOUND_ITEM_NOT_FOUND));

        if (!foundItem.getUser().getId().equals(userId)) {
            throw new CustomException(ErrorCode.FOUND_ITEM_ACCESS_DENIED);
        }

        foundItem.setStatus(FoundItemStatus.valueOf(request.getStatus()));
        foundItem.setUpdatedAt(LocalDateTime.now());


        return foundItemMapper.toStatusUpdateResponse(foundItem);
    }

    @Transactional(readOnly = true)
    public List<FoundItemDetailResponse> getMyFoundItems(int userId) {
        List<FoundItem> foundItems = foundItemRepository.findAllByUserId(userId);
        return foundItems.stream()
                .map(foundItemMapper::toDetailResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<FoundItemDetailResponse> getFoundItemsByViewport(FoundItemViewportRequest viewportRequest) {
        List<FoundItem> foundItems = foundItemRepository.findByCoordinatesWithin(
                viewportRequest.getMinLatitude(),
                viewportRequest.getMinLongitude(),
                viewportRequest.getMaxLatitude(),
                viewportRequest.getMaxLongitude());

        return foundItems.stream()
                .map(foundItemMapper::toDetailResponse)
                .collect(Collectors.toList());
    }

    public List<FoundItem> getStoredItemsFoundDaysAgo(int daysAgo) {
        return foundItemRepository.findByFoundAtAndStatus(LocalDate.now().minusDays(daysAgo), FoundItemStatus.STORED);
    }

}

