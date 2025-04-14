package com.ssfinder.domain.founditem.event;

import com.ssfinder.domain.founditem.entity.FoundItem;
import org.springframework.context.ApplicationEvent;

/**
 * packageName    : com.ssfinder.domain.founditem.event<br>
 * fileName       : FoundItemRegisteredEvent.java<br>
 * author         : okeio<br>
 * date           : 2025-04-10<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-10          okeio           최초생성<br>
 * <br>
 */
public class FoundItemRegisteredEvent extends ApplicationEvent {
    private final FoundItem foundItem;

    public FoundItemRegisteredEvent(Object source, FoundItem foundItem) {
        super(source);
        this.foundItem = foundItem;
    }

    public FoundItem getFoundItem() {
        return foundItem;
    }
}
