package com.ssfinder.domain.notification.event;

import com.ssfinder.domain.notification.service.NotificationHistoryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * packageName    : com.ssfinder.domain.notification.event<br>
 * fileName       : NotificationHistoryEventListener.java<br>
 * author         : okeio<br>
 * date           : 2025-04-01<br>
 * description    : NotificationHistoryEvent 발생 시 알림 내역 저장을 처리하는 이벤트 리스너입니다.<br>
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

    /**
     * NotificationHistoryEvent 수신 시 알림 내역을 저장합니다.
     *
     * <p>
     * 이벤트에 포함된 사용자 ID, 알림 타입, 제목, 본문을 기반으로 알림 이력을 생성하고 저장합니다.
     * 알림 전송 이후 이력을 기록하기 위해 비동기로 호출됩니다.
     * </p>
     *
     * @param event 알림 이력 생성을 위한 이벤트 객체
     */
    @EventListener
    public void handleNotificationHistoryEvent(NotificationHistoryEvent event) {
        notificationHistoryService.saveNotificationHistory(event.getUserId(), event.getType(), event.getTitle(), event.getBody());
    }

}
