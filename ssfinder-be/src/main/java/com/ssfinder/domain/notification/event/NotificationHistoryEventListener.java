package com.ssfinder.domain.notification.event;

import com.ssfinder.domain.notification.entity.NotificationHistory;
import com.ssfinder.domain.notification.service.NotificationHistoryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * packageName    : com.ssfinder.domain.notification.event<br>
 * fileName       : NotificationHistoryEventListener.java<br>
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
@Component
@RequiredArgsConstructor
public class NotificationHistoryEventListener {

    private final NotificationHistoryService notificationHistoryService;

    @EventListener
    public void handleNotificationHistoryEvent(NotificationHistoryEvent event) {
        log.info("[알림 이력 추가] {}", event.toString());
        NotificationHistory notificationHistory = NotificationHistory.builder()
                .user(event.getUser())
                .title(event.getTitle())
                .type(event.getType())
                .body(event.getBody())
                .build();
        notificationHistoryService.saveNotificationHistory(notificationHistory);
    }

}
