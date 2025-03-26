package com.ssfinder.domain.founditem.service;

import com.ssfinder.domain.founditem.dto.mapper.FoundItemMapper;
import com.ssfinder.domain.founditem.dto.request.FoundItemRegisterRequest;
import com.ssfinder.domain.founditem.dto.request.FoundItemUpdateRequest;
import com.ssfinder.domain.founditem.dto.response.FoundItemDetailResponse;
import com.ssfinder.domain.founditem.dto.response.FoundItemRegisterResponse;
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
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

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

    public List<FoundItem> getLostAll() {
        return null;
    }

    @Transactional
    public FoundItemRegisterResponse registerFoundItem(int userId, FoundItemRegisterRequest requestDTO) {

        FoundItem foundItem = foundItemMapper.toEntity(requestDTO);

        User user = userRepository.findById(userId).get();
        foundItem.setUser(user);

        ItemCategory itemCategory = itemCategoryRepository.findById(requestDTO.getItemCategoryId()).get();
        foundItem.setItemCategory(itemCategory);

        foundItem.setStatus(Status.valueOf(requestDTO.getStatus()));

        LocalDateTime now = LocalDateTime.now();
        foundItem.setCreatedAt(now);
        foundItem.setUpdatedAt(now);

        FoundItem savedItem = foundItemRepository.save(foundItem);

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

        // 수정 시간 업데이트
        foundItem.setUpdatedAt(LocalDateTime.now());

        // 엔티티 저장
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
}
