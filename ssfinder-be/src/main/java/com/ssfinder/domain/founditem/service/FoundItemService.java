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
import com.ssfinder.global.common.service.S3Service;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
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
        if(Objects.nonNull(requestDTO.getImage()) && !requestDTO.getImage().isEmpty()){
            imageUrl = s3Service.uploadFile(requestDTO.getImage(),"found");
        }

        foundItem.setImage(imageUrl);

        LocalDateTime now = LocalDateTime.now();
        foundItem.setCreatedAt(now);
        foundItem.setUpdatedAt(now);

        FoundItem savedItem = foundItemRepository.save(foundItem);

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

