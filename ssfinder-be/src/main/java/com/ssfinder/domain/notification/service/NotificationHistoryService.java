package com.ssfinder.domain.notification.service;

import com.ssfinder.domain.notification.dto.mapper.NotificationMapper;
import com.ssfinder.domain.notification.dto.response.NotificationSliceResponse;
import com.ssfinder.domain.notification.entity.NotificationHistory;
import com.ssfinder.domain.notification.entity.NotificationType;
import com.ssfinder.domain.notification.repository.NotificationHistoryRepository;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.service.UserService;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;

/**
 * packageName    : com.ssfinder.domain.notification.service<br>
 * fileName       : NotificationHistoryService.java<br>
 * author         : okeio<br>
 * date           : 2025-04-01<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-01          okeio           최초생성<br>
 * <br>
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class NotificationHistoryService {
    private final NotificationHistoryRepository notificationHistoryRepository;
    private final NotificationMapper notificationMapper;
    private final UserService userService;

    public NotificationHistory saveNotificationHistory(Integer userId, NotificationType type, String title, String body) {
        log.info("[알림 이력 추가] userId: {}, type: {}, body: {}", userId, type.name(), body);

        User user = userService.getReferenceById(userId);

        NotificationHistory notificationHistory = NotificationHistory.builder()
                .user(user)
                .title(title)
                .type(type)
                .body(body)
                .build();

        return notificationHistoryRepository.save(notificationHistory);
    }

    @Transactional(readOnly = true)
    public NotificationSliceResponse getNotificationHistory(Integer userId, NotificationType type, int page, int size, Integer lastId) {
        Slice<NotificationHistory> slice = fetchNotifications(userId, type, lastId, page, size);
        return notificationMapper.toNotificationSliceResponse(slice);
    }

    private Slice<NotificationHistory> fetchNotifications(Integer userId, NotificationType type, Integer lastId, int page, int size) {
        boolean hasType = !Objects.isNull(type);
        boolean hasLastId = !Objects.isNull(lastId);

        if (hasType && hasLastId) {
            return notificationHistoryRepository.findByUserIdAndTypeAndIdLessThanAndIsDeletedFalseOrderBySendAtDesc(userId, type, lastId, PageRequest.of(0, size));
        } else if (hasType) {
            return notificationHistoryRepository.findByUserIdAndTypeAndIsDeletedFalseOrderBySendAtDesc(userId, type, PageRequest.of(page, size));
        } else if (hasLastId) {
            // type 없이 lastId 이후 불러오는 메서드
            return notificationHistoryRepository.findByUserIdAndIdLessThanAndIsDeletedFalseOrderBySendAtDesc(userId, lastId, PageRequest.of(0, size));
        } else {
            // type 없이 모두 불러오는 메서드
            return notificationHistoryRepository.findByUserIdAndIsDeletedFalseOrderBySendAtDesc(userId, PageRequest.of(page, size));
        }
    }

    public void deleteNotificationHistory(Integer userId, Integer notificationId) {
        NotificationHistory notificationHistory = notificationHistoryRepository.findByIdAndUserId(notificationId, userId)
                .orElseThrow(() -> new CustomException(ErrorCode.NOTIFICATION_HISTORY_NOT_FOUND));

        if (notificationHistory.getIsDeleted()) {
            throw new CustomException(ErrorCode.NOTIFICATION_HISTORY_ALREADY_DELETED);
        }

        notificationHistory.setIsDeleted(true);
        notificationHistory.setDeletedAt(LocalDateTime.now());
    }

    public void deleteNotificationHistoryAllByType(Integer userId, NotificationType notificationType) {
        List<NotificationHistory> list = notificationHistoryRepository.findByUserIdAndTypeAndIsDeletedFalse(userId, notificationType);
        list.forEach(notificationHistory -> {
            notificationHistory.setIsDeleted(true);
            notificationHistory.setDeletedAt(LocalDateTime.now());
        });
    }

}