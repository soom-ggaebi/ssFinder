package com.ssfinder.domain.matchedItem.event;

import com.ssfinder.domain.matchedItem.entity.MatchedItem;
import org.springframework.context.ApplicationEvent;

import java.util.List;

/**
 * packageName    : com.ssfinder.domain.matchedItem.event<br>
 * fileName       : MatchedItemEvent.java<br>
 * author         : okeio<br>
 * date           : 2025-04-11<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-11          okeio           최초생성<br>
 * <br>
 */
public class MatchedItemEvent extends ApplicationEvent {
    private final List<MatchedItem> matchedItems;

    public MatchedItemEvent(Object source, List<MatchedItem> matchedItems) {
        super(source);
        this.matchedItems = matchedItems;
    }

    public List<MatchedItem> getMatchedItems() {
        return matchedItems;
    }
}
