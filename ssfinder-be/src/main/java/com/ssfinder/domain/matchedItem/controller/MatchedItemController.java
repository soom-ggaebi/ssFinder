package com.ssfinder.domain.matchedItem.controller;

import com.ssfinder.domain.matchedItem.dto.request.MatchedItemRequest;
import com.ssfinder.domain.matchedItem.dto.response.MatchedItemResponse;
import com.ssfinder.domain.matchedItem.service.MatchedItemService;
import com.ssfinder.global.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

/**
 * packageName    : com.ssfinder.domain.aimatching.controller<br>
 * fileName       : AiMatchingController.java<br>
 * author         : sonseohy<br>
 * date           : 2025-04-09<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-09          sonseohy           최초생성<br>
 * <br>
 */
@Slf4j
@RestController
@RequestMapping("/api/aimatching")
@RequiredArgsConstructor
public class MatchedItemController {
    private final MatchedItemService matchedItemService;

    @PostMapping("/find-similar")
    public ApiResponse<MatchedItemResponse> findSimilarItems(@RequestBody MatchedItemRequest request) {
        log.info("유사 습득물 찾기 요청: {}", request);

        MatchedItemResponse response = matchedItemService.findSimilarItems(request);

        return ApiResponse.ok(response);
    }

    @GetMapping("/matched-items/{lostItemId}")
    public ApiResponse<MatchedItemResponse> getMatchedItems(@PathVariable Integer lostItemId) {
        log.info("매칭된 습득물 목록 조회: lostItemId={}", lostItemId);

        MatchedItemResponse response = matchedItemService.getMatchedItems(lostItemId);

        return ApiResponse.ok(response);
    }
}