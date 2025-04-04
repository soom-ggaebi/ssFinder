package com.ssfinder.domain.notification.repository;

import com.ssfinder.domain.notification.entity.NotificationHistory;
import com.ssfinder.domain.notification.entity.NotificationType;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
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
 * 2025-04-03          okeio           타입 필터링 없는 알림 이력 조회 메서드 추가<br>
 * <br>
 */
public interface NotificationHistoryRepository extends JpaRepository<NotificationHistory, Integer> {

    Slice<NotificationHistory> findByUserIdAndIsDeletedFalseOrderBySendAtDesc(Integer userId, Pageable pageable);

    Slice<NotificationHistory> findByUserIdAndIdLessThanAndIsDeletedFalseOrderBySendAtDesc(Integer userId, Integer id, Pageable pageable);

    Slice<NotificationHistory> findByUserIdAndTypeAndIsDeletedFalseOrderBySendAtDesc(Integer userId, NotificationType type, Pageable pageable);

    Slice<NotificationHistory> findByUserIdAndTypeAndIdLessThanAndIsDeletedFalseOrderBySendAtDesc(Integer userId, NotificationType type, Integer id, Pageable pageable);

    Optional<NotificationHistory> findByIdAndUserId(Integer id, Integer userId);

    List<NotificationHistory> findByUserIdAndTypeAndIsDeletedFalse(Integer userId, NotificationType type);
}
