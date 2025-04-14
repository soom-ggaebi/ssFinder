package com.ssfinder.domain.founditem.event;

import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.matchedItem.dto.request.MatchedItemRequest2;
import com.ssfinder.domain.matchedItem.dto.response.MatchedItemResponse;
import com.ssfinder.domain.matchedItem.service.MatchedItemSaveService;
import com.ssfinder.domain.matchedItem.service.MatchedItemService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * packageName    : com.ssfinder.domain.matchedItem.event<br>
 * fileName       : MatchedItemListener.java<br>
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
public class FoundItemRegisteredListener {

    private final MatchedItemService matchedItemService;
    private final MatchedItemSaveService matchedItemSaveService;

    @Async
    @TransactionalEventListener
    public void handleFoundItemRegisteredEvent(FoundItemRegisteredEvent event) {
        FoundItem foundItem = event.getFoundItem();
        // 습득물 업로드 시, 분실물들 간의 매칭 진행
        MatchedItemResponse matchingResponse = matchedItemService.findSimilarItems2(
                MatchedItemRequest2.builder()
                        .foundItemId(foundItem.getId())
                        .itemCategoryId(foundItem.getItemCategory().getId())
                        .title(foundItem.getName())
                        .color(foundItem.getColor())
                        .detail(foundItem.getDetail())
                        .location(foundItem.getLocation())
                        .image(foundItem.getImage())
                        .threshold(0.7f)
                        .build()
        );

        if (matchingResponse != null && matchingResponse.isSuccess() &&
                matchingResponse.getResult() != null && foundItem.getId() != null) {
            matchedItemSaveService.saveMatchingResults2(foundItem.getId(), matchingResponse);
        }
    }
}
