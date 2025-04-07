package com.ssfinder.domain.lostitem.service;

import com.ssfinder.domain.itemcategory.entity.ItemCategory;
import com.ssfinder.domain.itemcategory.repository.ItemCategoryRepository;
import com.ssfinder.domain.lostitem.dto.mapper.LostItemMapper;
import com.ssfinder.domain.lostitem.dto.request.LostItemRegisterRequest;
import com.ssfinder.domain.lostitem.dto.request.LostItemStatusUpdateRequest;
import com.ssfinder.domain.lostitem.dto.request.LostItemUpdateRequest;
import com.ssfinder.domain.lostitem.dto.response.LostItemResponse;
import com.ssfinder.domain.lostitem.dto.response.LostItemStatusUpdateResponse;
import com.ssfinder.domain.lostitem.dto.response.LostItemUpdateResponse;
import com.ssfinder.domain.lostitem.entity.LostItem;
import com.ssfinder.domain.lostitem.entity.LostItemStatus;
import com.ssfinder.domain.lostitem.repository.LostItemRepository;
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
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
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
 * 2025-03-27          joker901010           코드리뷰 수정<br>
 * <br>
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class LostItemService {

    private final LostItemRepository lostItemRepository;
    private final ItemCategoryRepository itemCategoryRepository;
    private final UserService userService;
    private final LostItemMapper lostItemMapper;
    private final S3Service s3Service;

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

        User user = userService.findUserById(userId);
        lostItem.setUser(user);

        ItemCategory category = itemCategoryRepository.findById(request.getItemCategoryId())
                .orElseThrow(() -> new CustomException(ErrorCode.CATEGORY_NOT_FOUND));
        lostItem.setItemCategory(category);

        lostItem.setStatus(LostItemStatus.LOST);

        if(Objects.nonNull(request.getLatitude()) && Objects.nonNull(request.getLongitude())) {
            Point coordinates = geometryFactory.createPoint(new Coordinate(request.getLongitude(), request.getLatitude()));
            lostItem.setCoordinates(coordinates);
        }

        String imageUrl = null;
        if(Objects.nonNull(request.getImage()) && !request.getImage().isEmpty()){
            imageUrl = s3Service.uploadFile(request.getImage(), "lost");
        }

        lostItem.setImage(imageUrl);

        LocalDateTime now = LocalDateTime.now();
        lostItem.setCreatedAt(now);
        lostItem.setUpdatedAt(now);

        return lostItemRepository.save(lostItem);
    }

    @Transactional(readOnly = true)
    public LostItemResponse getLostItem(int userId, int lostId) {
        LostItem lostItem = lostItemRepository.findById(lostId)
                .orElseThrow(() -> new CustomException(ErrorCode.LOST_ITEM_NOT_FOUND));

        if(!lostItem.getUser().getId().equals(userId)) {
            throw new CustomException(ErrorCode.LOST_ITEM_ACCESS_DENIED);
        }

        return lostItemMapper.toResponse(lostItem);
    }

    @Transactional
    public LostItemUpdateResponse updateLostItem(Integer userId, Integer lostId, LostItemUpdateRequest request){
        LostItem lostItem = lostItemRepository.findById(lostId)
                .orElseThrow(() -> new CustomException(ErrorCode.LOST_ITEM_NOT_FOUND));

        if(!lostItem.getUser().getId().equals(userId)) {
            throw new CustomException(ErrorCode.LOST_ITEM_ACCESS_DENIED);
        }

        lostItemMapper.updateLostItemFromRequest(request, lostItem);

        if(Objects.nonNull(request.getLatitude()) && Objects.nonNull(request.getLongitude())) {
            Point coordinates = geometryFactory.createPoint(new Coordinate(request.getLongitude(), request.getLatitude()));
            lostItem.setCoordinates(coordinates);
        }

        String imageUrl = lostItem.getImage();
        if(Objects.nonNull(request.getImage()) && !request.getImage().isEmpty()){
            if (Objects.nonNull(imageUrl)){
                imageUrl = s3Service.updateFile(imageUrl, request.getImage());
            } else {
                imageUrl = s3Service.uploadFile(request.getImage(), "lost");
            }
        }

        lostItem.setImage(imageUrl);

        lostItem.setUpdatedAt(LocalDateTime.now());

        return lostItemMapper.toUpdateResponse(lostItem);
    }

    @Transactional
    public void deleteLostItem(int userId, int lostId) {
        LostItem lostItem = lostItemRepository.findById(lostId)
                .orElseThrow(() -> new CustomException(ErrorCode.LOST_ITEM_NOT_FOUND));

        if (!lostItem.getUser().getId().equals(userId)) {
            throw new CustomException(ErrorCode.LOST_ITEM_ACCESS_DENIED);
        }

        if (Objects.nonNull(lostItem.getImage())) {
            s3Service.deleteFile(lostItem.getImage());
        }
        lostItemRepository.delete(lostItem);
    }

    @Transactional
    public LostItemStatusUpdateResponse updateLostItemStatus(Integer userId, Integer lostId, LostItemStatusUpdateRequest request) {
        LostItem lostItem = lostItemRepository.findById(lostId)
                .orElseThrow(() -> new CustomException(ErrorCode.LOST_ITEM_NOT_FOUND));
        if(!lostItem.getUser().getId().equals(userId)) {
            throw new CustomException(ErrorCode.LOST_ITEM_ACCESS_DENIED);
        }
        lostItem.setStatus(LostItemStatus.valueOf(request.getStatus()));
        lostItem.setUpdatedAt(LocalDateTime.now());

        return lostItemMapper.toStatusUpdateResponse(lostItem);
    }
}
