package com.ssfinder.domain.lostitem.service;

import com.ssfinder.domain.item.entity.ItemCategory;
import com.ssfinder.domain.item.repository.ItemCategoryRepository;
import com.ssfinder.domain.lostitem.dto.mapper.LostItemMapper;
import com.ssfinder.domain.lostitem.dto.request.LostItemRegisterRequest;
import com.ssfinder.domain.lostitem.dto.request.LostItemStatusUpdateRequest;
import com.ssfinder.domain.lostitem.dto.request.LostItemUpdateRequest;
import com.ssfinder.domain.lostitem.dto.response.LostItemResponse;
import com.ssfinder.domain.lostitem.dto.response.LostItemStatusUpdateResponse;
import com.ssfinder.domain.lostitem.dto.response.LostItemUpdateResponse;
import com.ssfinder.domain.lostitem.entity.LostItem;
import com.ssfinder.domain.lostitem.entity.Status;
import com.ssfinder.domain.lostitem.repository.LostItemRepository;
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
 * packageName    : com.ssfinder.domain.lost.service<br>
 * fileName       : LostService.java<br>
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
@RequiredArgsConstructor
@Transactional
public class LostItemService {

    private final LostItemRepository lostItemRepository;
    private final ItemCategoryRepository itemCategoryRepository;
    private final UserRepository userRepository;
    private final LostItemMapper lostItemMapper;

    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    @Transactional(readOnly = true)
    public List<LostItemResponse> getLostAll(Integer userId) {
        List<LostItem> lostItems = lostItemRepository.findAllByUserId(userId);
        return lostItems.stream()
                .map(lostItemMapper::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public LostItem registerLostItem(int userId, LostItemRegisterRequest request) {
        LostItem lostItem = lostItemMapper.toEntity(request);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new CustomException(ErrorCode.INVALID_INPUT_VALUE));
        lostItem.setUser(user);

        ItemCategory category = itemCategoryRepository.findById(request.getItemCategoryId())
                .orElseThrow(() -> new CustomException(ErrorCode.INVALID_INPUT_VALUE));
        lostItem.setItemCategory(category);

        lostItem.setStatus(Status.LOST);
        // 좌표 설정 (경도, 위도 순)
        if(request.getLatitude() != null && request.getLongitude() != null) {
            Point coordinates = geometryFactory.createPoint(new Coordinate(request.getLongitude(), request.getLatitude()));
            lostItem.setCoordinates(coordinates);
        } else {
            throw new CustomException(ErrorCode.INVALID_INPUT_VALUE);
        }

        LocalDateTime now = LocalDateTime.now();
        lostItem.setCreatedAt(now);
        lostItem.setUpdatedAt(now);

        return lostItemRepository.save(lostItem);
    }

    @Transactional(readOnly = true)
    public LostItemResponse getLostItem(int lostId) {
        LostItem lostItem = lostItemRepository.findById(lostId)
                .orElseThrow(() -> new CustomException(ErrorCode.INVALID_INPUT_VALUE));
        return lostItemMapper.toResponse(lostItem);
    }

    @Transactional
    public LostItemUpdateResponse updateLostItem(Integer userId, Integer lostId, LostItemUpdateRequest request) {
        LostItem lostItem = lostItemRepository.findById(lostId)
                .orElseThrow(() -> new CustomException(ErrorCode.INVALID_INPUT_VALUE));

        if(!lostItem.getUser().getId().equals(userId)) {
            throw new CustomException(ErrorCode.UNAUTHORIZED);
        }

        lostItemMapper.updateLostItemFromRequest(request, lostItem);

        if(request.getLatitude() != null && request.getLongitude() != null) {
            Point coordinates = geometryFactory.createPoint(new Coordinate(request.getLongitude(), request.getLatitude()));
            lostItem.setCoordinates(coordinates);
        }
        lostItem.setUpdatedAt(LocalDateTime.now());

        LostItem updatedLostItem = lostItemRepository.save(lostItem);
        return lostItemMapper.toUpdateResponse(updatedLostItem);
    }

    @Transactional
    public void deleteLostItem(int lostId) {
        LostItem lostItem = lostItemRepository.findById(lostId)
                .orElseThrow(() -> new CustomException(ErrorCode.INVALID_INPUT_VALUE));
        lostItemRepository.delete(lostItem);
    }

    @Transactional
    public LostItemStatusUpdateResponse updateLostItemStatus(Integer userId, Integer lostId, LostItemStatusUpdateRequest request) {
        LostItem lostItem = lostItemRepository.findById(lostId)
                .orElseThrow(() -> new CustomException(ErrorCode.INVALID_INPUT_VALUE));
        if(!lostItem.getUser().getId().equals(userId)) {
            throw new CustomException(ErrorCode.UNAUTHORIZED);
        }
        lostItem.setStatus(Status.valueOf(request.getStatus()));
        lostItem.setUpdatedAt(LocalDateTime.now());
        LostItem updatedLostItem = lostItemRepository.save(lostItem);
        return lostItemMapper.toStatusUpdateResponse(updatedLostItem);
    }
}
