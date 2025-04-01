package com.ssfinder.domain.notification.repository;

import com.ssfinder.domain.notification.entity.NotificationHistory;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * packageName    : com.ssfinder.domain.notification.repository<br>
 * fileName       : NotificationRepository.java<br>
 * author         : joker901010<br>
 * date           : 2025-03-19<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          joker901010           최초생성<br>
 * <br>
 */
public interface NotificationHistoryRepository extends JpaRepository<NotificationHistory, Integer> {
}
