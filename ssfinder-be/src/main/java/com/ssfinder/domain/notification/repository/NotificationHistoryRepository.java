package com.ssfinder.domain.notification.repository;

import com.ssfinder.domain.notification.entity.NotificationHistory;
import com.ssfinder.domain.notification.entity.NotificationType;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.Optional;

/**
 * packageName    : com.ssfinder.domain.notification.repository<br>
 * fileName       : NotificationRepository.java<br>
 * author         : okeio<br>
 * date           : 2025-04-02<br>
 * description    : NotificationHistoryRepository <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-02          okeio           최초생성<br>
 * <br>
 */
public interface NotificationHistoryRepository extends JpaRepository<NotificationHistory, Integer> {
    // TODO 기존 조회 로직에서 soft delete 체크
    Slice<NotificationHistory> findByUserIdAndTypeAndIsDeletedFalseOrderBySendAtDesc(Integer userId, NotificationType type, Pageable pageable);

    Slice<NotificationHistory> findByUserIdAndTypeAndIsDeletedFalseAndSendAtLessThanOrderBySendAtDesc(Integer userId, NotificationType type, LocalDateTime sendAt, Pageable pageable);

    Optional<NotificationHistory> findByIdAndUserId(Integer id, Integer userId);

}
