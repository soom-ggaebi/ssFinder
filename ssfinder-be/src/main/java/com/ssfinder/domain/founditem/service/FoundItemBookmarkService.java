package com.ssfinder.domain.founditem.service;

import com.ssfinder.domain.founditem.dto.mapper.FoundItemBookmarkMapper;
import com.ssfinder.domain.founditem.dto.response.FoundItemBookmarkResponse;
import com.ssfinder.domain.founditem.dto.response.FoundItemSummaryResponse;
import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.founditem.entity.FoundItemBookmark;
import com.ssfinder.domain.founditem.repository.FoundItemBookmarkRepository;
import com.ssfinder.domain.founditem.repository.FoundItemRepository;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.service.UserService;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * packageName    : com.ssfinder.domain.found.service<br>
 * fileName       : FoundItemBookmarkService.java<br>
 * author         : joker901010<br>
 * date           : 2025-03-26<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-26          joker901010           최초생성<br>
 * 2025-03-27          joker901010           코드리뷰 수정<br>
 * <br>
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class FoundItemBookmarkService {

    private final FoundItemBookmarkRepository bookmarkRepository;
    private final FoundItemRepository foundItemRepository;
    private final FoundItemBookmarkMapper bookmarkMapper;
    private final UserService userService;

    @Transactional
    public FoundItemBookmarkResponse registerBookmark(Integer userId, Integer foundItemId) {

        bookmarkRepository.findByUserIdAndFoundItemId(userId, foundItemId)
                .ifPresent(b -> { throw new CustomException(ErrorCode.BOOKMARK_DUPLICATED); });

        FoundItem foundItem = foundItemRepository.findById(foundItemId)
                .orElseThrow(() -> new CustomException(ErrorCode.FOUND_ITEM_NOT_FOUND));

        FoundItemBookmark bookmark = bookmarkMapper.toEntity(foundItemId);

        User user = userService.findUserById(userId);

        bookmark.setUser(user);
        bookmark.setFoundItem(foundItem);

        return bookmarkMapper.toResponse(bookmark);
    }

    @Transactional(readOnly = true)
    public List<FoundItemBookmarkResponse> getBookmarksByUser(Integer userId) {
        List<FoundItemBookmark> bookmarks = bookmarkRepository.findByUserId(userId);
        return bookmarks.stream()
                .map(bookmarkMapper::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public void deleteBookmark(Integer userId, Integer bookmarkId) {

        FoundItemBookmark bookmark = bookmarkRepository.findById(bookmarkId)
                .orElseThrow(() -> new CustomException(ErrorCode.BOOKMARK_NOT_FOUND));

        if (!bookmark.getUser().getId().equals(userId)) {
            throw new CustomException(ErrorCode.BOOKMARK_ACCESS_DENIED);
        }
        bookmarkRepository.delete(bookmark);
    }

    @Transactional
    public void deleteAllBookmarksByFoundItemId(Integer foundItemId) {
        bookmarkRepository.deleteByFoundItemId(foundItemId);
    }

    @Transactional(readOnly = true)
    public boolean isItemBookmarkedByUser(Integer userId, int foundId) {

        if (userId == null) {
            return false;
        }

        return bookmarkRepository.existsByUserIdAndFoundItemId(userId, foundId);
    }

    @Transactional(readOnly = true)
    public void applyBookmarkInfoToItems(Integer userId, List<FoundItemSummaryResponse> items) {
        if (items == null || items.isEmpty()) {
            return;
        }

        try {
            List<Integer> bookmarkedIds = getBookmarkedItemIdsByUser(userId);
            for (FoundItemSummaryResponse item : items) {
                boolean isBookmarked = bookmarkedIds.contains(item.getId());
                item.setBookmarked(isBookmarked);
            }
        } catch (Exception e) {
            log.error("북마크 정보 조회 중 오류: {}", e.getMessage());
            items.forEach(item -> item.setBookmarked(false));
        }
    }

    @Transactional(readOnly = true)
    public List<Integer> getBookmarkedItemIdsByUser(Integer userId) {
        return bookmarkRepository.findFoundItemIdsByUserId(userId);
    }
}