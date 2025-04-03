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
    public NotificationSliceResponse getNotificationHistory(Integer userId, NotificationType notificationType, int page, int size, Integer lastId) {
        Slice<NotificationHistory> slice = null;

        if (Objects.isNull(lastId)) {
            slice = notificationHistoryRepository.findByUserIdAndTypeAndIsDeletedFalseOrderBySendAtDesc(userId, notificationType, PageRequest.of(page, size));
        } else {
            slice = getNotificationHistoryAfterLastId(userId, notificationType, lastId, PageRequest.of(0, size));
        }

        return notificationMapper.toNotificationSliceResponse(slice);
    }

    @Transactional(readOnly = true)
    public Slice<NotificationHistory> getNotificationHistoryAfterLastId(Integer userId, NotificationType notificationType, int lastId, Pageable pageable) {
        NotificationHistory lastNotification = notificationHistoryRepository.findById(lastId)
                .orElseThrow(() -> new CustomException(ErrorCode.NOTIFICATION_HISTORY_NOT_FOUND));

        LocalDateTime lastDateTime = lastNotification.getSendAt();

        return notificationHistoryRepository.findByUserIdAndTypeAndIsDeletedFalseAndSendAtLessThanOrderBySendAtDesc(userId, notificationType, lastDateTime, pageable);
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

}