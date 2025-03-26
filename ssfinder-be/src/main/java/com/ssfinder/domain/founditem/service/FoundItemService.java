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
import com.ssfinder.domain.founditem.entity.Status;
import com.ssfinder.domain.founditem.repository.FoundItemRepository;
import com.ssfinder.domain.item.entity.ItemCategory;
import com.ssfinder.domain.item.repository.ItemCategoryRepository;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.repository.UserRepository;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
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
 * <br>
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class FoundItemService {

    private final FoundItemRepository foundItemRepository;
    private final FoundItemMapper foundItemMapper;
    private final UserRepository userRepository;
    private final ItemCategoryRepository itemCategoryRepository;

    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    @Transactional
    public FoundItemRegisterResponse registerFoundItem(int userId, FoundItemRegisterRequest requestDTO) {
        FoundItem foundItem;
        try {
            foundItem = foundItemMapper.toEntity(requestDTO);
        } catch(Exception e) {
            throw e;
        }

        User user = userRepository.findById(userId).orElseThrow(() -> new CustomException(ErrorCode.INVALID_INPUT_VALUE));
        foundItem.setUser(user);

        ItemCategory itemCategory = itemCategoryRepository.findById(requestDTO.getItemCategoryId())
                .orElseThrow(() -> new CustomException(ErrorCode.INVALID_INPUT_VALUE));
        foundItem.setItemCategory(itemCategory);

        if (requestDTO.getStatus() != null) {
            foundItem.setStatus(Status.valueOf(requestDTO.getStatus()));
        }

        if (requestDTO.getLatitude() != null && requestDTO.getLongitude() != null) {
            Point coordinates = geometryFactory.createPoint(new Coordinate(requestDTO.getLongitude(), requestDTO.getLatitude()));
            foundItem.setCoordinates(coordinates);
        } else {
            throw new CustomException(ErrorCode.INVALID_INPUT_VALUE);
        }

        LocalDateTime now = LocalDateTime.now();
        foundItem.setCreatedAt(now);
        foundItem.setUpdatedAt(now);
        System.out.println("save 직전, foundItem: " + foundItem);
        FoundItem savedItem = foundItemRepository.save(foundItem);
        System.out.println("save 후, savedItem: " + savedItem);
        return foundItemMapper.toResponse(savedItem);
    }


    @Transactional(readOnly = true)
    public FoundItemDetailResponse getFoundItemDetail(int foundId) {
        FoundItem foundItem = foundItemRepository.findById(foundId)
                .orElseThrow(() -> new CustomException(ErrorCode.INVALID_INPUT_VALUE));
        return foundItemMapper.toDetailResponse(foundItem);
    }

    @Transactional
    public FoundItemUpdateResponse updateFoundItem(Integer userId, Integer foundId, FoundItemUpdateRequest updateRequest) {
        // NOT FOUND 나오면 수정
        FoundItem foundItem = foundItemRepository.findById(foundId)
                .orElseThrow(() -> new CustomException(ErrorCode.INVALID_INPUT_VALUE));

        if (!foundItem.getUser().getId().equals(userId)) {
            throw new CustomException(ErrorCode.UNAUTHORIZED);
        }

        foundItemMapper.updateFoundItemFromRequest(updateRequest, foundItem);

        if (updateRequest.getLatitude() != null && updateRequest.getLongitude() != null) {
            Point coordinates = geometryFactory.createPoint(new Coordinate(updateRequest.getLongitude(), updateRequest.getLatitude()));
            foundItem.setCoordinates(coordinates);
        }

        foundItem.setUpdatedAt(LocalDateTime.now());

        FoundItem updatedItem = foundItemRepository.save(foundItem);
        return foundItemMapper.toUpdateResponse(updatedItem);
    }

    @Transactional
    public void deleteFoundItem(Integer userId, Integer foundId) {
        // ErrorCode NotFound 업데이트 되면 수정 예정
        FoundItem foundItem = foundItemRepository.findById(foundId)
                .orElseThrow(() -> new CustomException(ErrorCode.INVALID_INPUT_VALUE));
        foundItemRepository.delete(foundItem);
    }

    @Transactional
    public FoundItemStatusUpdateResponse updateFoundItemStatus(int userId, Integer foundId, FoundItemStatusUpdateRequest request) {

        // Not FOUNd errorcode
        FoundItem foundItem = foundItemRepository.findById(foundId)
                .orElseThrow(() -> new CustomException(ErrorCode.INVALID_INPUT_VALUE));

        if (!foundItem.getUser().getId().equals(userId)) {
            throw new CustomException(ErrorCode.UNAUTHORIZED);
        }

        foundItem.setStatus(Status.valueOf(request.getStatus()));
        foundItem.setUpdatedAt(LocalDateTime.now());

        FoundItem updatedItem = foundItemRepository.save(foundItem);

        return foundItemMapper.toStatusUpdateResponse(updatedItem);
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
}

