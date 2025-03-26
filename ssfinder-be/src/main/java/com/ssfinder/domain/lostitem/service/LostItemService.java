package com.ssfinder.domain.lostitem.service;

import com.ssfinder.domain.item.entity.ItemCategory;
import com.ssfinder.domain.item.entity.Level;
import com.ssfinder.domain.item.repository.ItemCategoryRepository;
import com.ssfinder.domain.lostitem.dto.request.LostItemRegisterRequest;
import com.ssfinder.domain.lostitem.dto.response.LostItemResponse;
import com.ssfinder.domain.lostitem.entity.LostItem;
import com.ssfinder.domain.lostitem.entity.Status;
import com.ssfinder.domain.lostitem.repository.LostItemRepository;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.transaction.annotation.Transactional;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

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

    public List<LostItem> getLostAll(int userId) {
        List<LostItem> lostItemList = lostItemRepository.findAllByUser_Id(userId);

        return lostItemList;
    }


    @Transactional
    public LostItem registerLostItem(int userId, @Valid LostItemRegisterRequest lostItemRegisterRequest) {
        // 1. 사용자 조회
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // 2. 아이템 카테고리 조회/등록
        ItemCategory itemCategory = getOrCreateItemCategory(lostItemRegisterRequest.getItemCategoryName(), lostItemRegisterRequest.getLevel());

        // 3. LostItem 엔티티 생성
        LostItem lostItem = LostItem.builder()
                .user(user)
                .itemCategory(itemCategory)  // 조회한 아이템 카테고리 설정
                .title(lostItemRegisterRequest.getTitle())
                .color(lostItemRegisterRequest.getColor())
                .lostAt(lostItemRegisterRequest.getLostAt())
                .location(lostItemRegisterRequest.getLocation())
                .detail(lostItemRegisterRequest.getDetail())
                .image(lostItemRegisterRequest.getImage())
                .status(Status.LOST)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        // 4. LostItem 저장
        return lostItemRepository.save(lostItem);
    }

    // 아이템 카테고리 조회 또는 등록
    private ItemCategory getOrCreateItemCategory(String itemCategoryName, Level level) {
        // 부모 카테고리가 있는지 먼저 확인 (MAJOR일 경우)
        Optional<ItemCategory> parentCategory = itemCategoryRepository.findByNameAndLevel(itemCategoryName, Level.MAJOR);

        ItemCategory parentItemCategory = parentCategory.orElseGet(() -> {
            // 없으면 새로운 MAJOR 레벨 카테고리로 등록
            ItemCategory newCategory = ItemCategory.builder()
                    .name(itemCategoryName)
                    .level(Level.MAJOR)
                    .build();
            return itemCategoryRepository.save(newCategory);
        });

        // MINOR 레벨 카테고리 확인
        Optional<ItemCategory> minorCategory = itemCategoryRepository.findByNameAndLevel(itemCategoryName, Level.MINOR);

        if (minorCategory.isPresent()) {
            return minorCategory.get();
        } else {
            // MINOR 카테고리 없다면 새로 등록
            ItemCategory newMinorCategory = ItemCategory.builder()
                    .name(itemCategoryName)
                    .level(Level.MINOR)
                    .itemCategory(parentItemCategory)  // MAJOR 카테고리를 부모로 설정
                    .build();
            return itemCategoryRepository.save(newMinorCategory);
        }
    }

    public LostItemResponse getLostItem(int lostId) {
        LostItem lostItem = lostItemRepository.findById(lostId)
                .orElseThrow(() -> new EntityNotFoundException("Lost item not found"));

        return LostItemResponse.builder()
                .id(lostItem.getId())
                .user(lostItem.getUser())
                .itemCategoryId(lostItem.getItemCategory().getId())
                .title(lostItem.getTitle())
                .color(lostItem.getColor())
                .lostAt(lostItem.getLostAt())
                .location(lostItem.getLocation())
                .detail(lostItem.getDetail())
                .image(lostItem.getImage())
                .status(lostItem.getStatus().toString())
                .createdAt(lostItem.getCreatedAt())
                .updatedAt(lostItem.getUpdatedAt())
                .build();
    }

    public void deleteLostItem(int lostId) {
        LostItem lostItem = lostItemRepository.findById(lostId)
                .orElseThrow(() -> new EntityNotFoundException("Lost item not found"));

        lostItemRepository.delete(lostItem);
    }
}
