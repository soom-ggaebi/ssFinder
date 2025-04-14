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
 * description    : 사용자 알림 내역 저장, 조회 및 삭제 처리를 담당하는 서비스입니다.<br>
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

    /**
     * 알림 내역을 저장합니다.
     *
     * <p>
     * 사용자의 알림 내역을 데이터베이스에 저장하며, 알림의 제목, 내용, 유형 등을 포함합니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @param type 알림 유형
     * @param title 알림 제목
     * @param body 알림 내용
     * @return 저장된 {@link NotificationHistory} 엔티티
     */
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

    /**
     * 알림 내역을 페이지 단위로 조회합니다.
     *
     * <p>
     * 사용자 ID 및 알림 유형을 기반으로 페이징하여 알림 내역을 조회합니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @param type 필터링할 알림 유형 (nullable)
     * @param page 페이지 번호
     * @param size 페이지 크기
     * @param lastId 마지막 알림 ID (무한 스크롤용 nullable)
     * @return 페이징 처리된 알림 응답 {@link NotificationSliceResponse}
     */
    @Transactional(readOnly = true)
    public NotificationSliceResponse getNotificationHistory(Integer userId, NotificationType type, int page, int size, Integer lastId) {
        Slice<NotificationHistory> slice = fetchNotifications(userId, type, lastId, page, size);
        return notificationMapper.toNotificationSliceResponse(slice);
    }

    /**
     * 알림 내역을 조회 조건에 따라 조회합니다.
     *
     * <p>
     * 알림 유형 및 마지막 알림 ID 조건을 기반으로 알림 내역을 조회합니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @param type 알림 유형 (nullable)
     * @param lastId 마지막 알림 ID (nullable)
     * @param page 페이지 번호
     * @param size 페이지 크기
     * @return 조건에 맞는 알림 {@link Slice}
     */
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

    /**
     * 개별 알림 내역을 삭제 처리합니다.
     *
     * <p>
     * 알림 내역을 삭제 처리하며, 이미 삭제된 알림인 경우 예외를 발생시킵니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @param notificationId 삭제할 알림 ID
     * @throws CustomException 알림이 존재하지 않거나 이미 삭제된 경우
     */
    public void deleteNotificationHistory(Integer userId, Integer notificationId) {
        NotificationHistory notificationHistory = notificationHistoryRepository.findByIdAndUserId(notificationId, userId)
                .orElseThrow(() -> new CustomException(ErrorCode.NOTIFICATION_HISTORY_NOT_FOUND));

        if (notificationHistory.getIsDeleted()) {
            throw new CustomException(ErrorCode.NOTIFICATION_HISTORY_ALREADY_DELETED);
        }

        notificationHistory.setIsDeleted(true);
        notificationHistory.setDeletedAt(LocalDateTime.now());
    }

    /**
     * 특정 유형의 모든 알림 내역을 삭제 처리합니다.
     *
     * <p>
     * 지정된 알림 유형에 해당하는 모든 알림을 삭제 처리합니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @param notificationType 삭제할 알림 유형
     */
    public void deleteNotificationHistoryAllByType(Integer userId, NotificationType notificationType) {
        List<NotificationHistory> list = notificationHistoryRepository.findByUserIdAndTypeAndIsDeletedFalse(userId, notificationType);
        list.forEach(notificationHistory -> {
            notificationHistory.setIsDeleted(true);
            notificationHistory.setDeletedAt(LocalDateTime.now());
        });
    }
}