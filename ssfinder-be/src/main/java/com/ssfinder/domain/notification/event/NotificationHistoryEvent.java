package com.ssfinder.domain.notification.event;

import com.ssfinder.domain.notification.entity.NotificationType;
import lombok.Getter;
import org.springframework.context.ApplicationEvent;

/**
 * packageName    : com.ssfinder.domain.notification.event<br>
 * fileName       : NotificationHistoryEvent.java<br>
 * author         : okeio<br>
 * date           : 2025-04-01<br>
 * description    : 알림 발송 후 알림 내역 저장을 위해 발행되는 이벤트 클래스입니다.<br>
 *                  사용자 ID, 알림 제목, 내용, 유형 정보를 포함합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-01          okeio           최초생성<br>
 * <br>
 */
@Getter
public class NotificationHistoryEvent extends ApplicationEvent {

    private final Integer userId;
    private final String title;
    private final String body;
    private final NotificationType type;

    public NotificationHistoryEvent(Object source, Integer userId, String title, String body, NotificationType type) {
        super(source);

        this.userId = userId;
        this.title = title;
        this.body = body;
        this.type = type;
    }
}
