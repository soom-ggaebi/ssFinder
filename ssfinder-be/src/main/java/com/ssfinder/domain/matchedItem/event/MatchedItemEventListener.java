package com.ssfinder.domain.matchedItem.event;

import com.ssfinder.domain.notification.dto.request.AiMatchNotificationRequest;
import com.ssfinder.domain.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.util.ArrayList;
import java.util.List;

/**
 * packageName    : com.ssfinder.domain.matchedItem.event<br>
 * fileName       : MatchedItemEventListener.java<br>
 * author         : okeio<br>
 * date           : 2025-04-11<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-11          okeio           최초생성<br>
 * <br>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class MatchedItemEventListener {
    private final NotificationService notificationService;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void handleMatchedItemEvent(MatchedItemEvent event) {
        List<AiMatchNotificationRequest> list = new ArrayList<>();

        event.getMatchedItems().forEach(matchedItem -> {
            list.add(AiMatchNotificationRequest.builder()
                    .foundItemId(matchedItem.getFoundItem().getId())
                    .lostItemId(matchedItem.getLostItem().getId())
                    .build());
        });

        notificationService.sendItemMatchingNotifications(list);
    }
}
