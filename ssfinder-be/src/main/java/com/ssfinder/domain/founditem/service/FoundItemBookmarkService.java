package com.ssfinder.domain.founditem.service;

import com.ssfinder.domain.founditem.dto.mapper.FoundItemBookmarkMapper;
import com.ssfinder.domain.founditem.dto.response.FoundItemBookmarkResponse;
import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.founditem.entity.FoundItemBookmark;
import com.ssfinder.domain.founditem.repository.FoundItemBookmarkRepository;
import com.ssfinder.domain.founditem.repository.FoundItemRepository;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.repository.UserRepository;
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
    private final UserRepository userRepository;

    @Transactional
    public FoundItemBookmarkResponse registerBookmark(Integer userId, Integer foundItemId) {

        // 중복등록 ErrorCode 만들기
        bookmarkRepository.findByUserIdAndFoundItemId(userId, foundItemId)
                .ifPresent(b -> { throw new CustomException(ErrorCode.INVALID_INPUT_VALUE); });

        // NOTFOUND 나오면 바꾸기
        FoundItem foundItem = foundItemRepository.findById(foundItemId)
                .orElseThrow(() -> new CustomException(ErrorCode.INVALID_INPUT_VALUE));

        FoundItemBookmark bookmark = bookmarkMapper.toEntity(foundItemId);

        // NOTFOUND 나오면 바꾸기
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new CustomException(ErrorCode.INVALID_INPUT_VALUE));

        bookmark.setUser(user);
        bookmark.setFoundItem(foundItem);

        FoundItemBookmark saved = bookmarkRepository.save(bookmark);
        return bookmarkMapper.toResponse(saved);
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
        // NOT FOUND 나오면 바꿀거
        FoundItemBookmark bookmark = bookmarkRepository.findById(bookmarkId)
                .orElseThrow(() -> new CustomException(ErrorCode.INVALID_INPUT_VALUE));

        if (!bookmark.getUser().getId().equals(userId)) {
            throw new CustomException(ErrorCode.UNAUTHORIZED);
        }
        bookmarkRepository.delete(bookmark);
    }

}