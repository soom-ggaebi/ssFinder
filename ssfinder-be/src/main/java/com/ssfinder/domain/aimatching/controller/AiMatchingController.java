package com.ssfinder.domain.aimatching.controller;

import com.ssfinder.domain.aimatching.dto.request.AiMatchingRequest;
import com.ssfinder.domain.aimatching.dto.response.AiMatchingResponse;
import com.ssfinder.domain.aimatching.service.AiMatchingService;
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
public class AiMatchingController {
    private final AiMatchingService aiMatchingService;

    @PostMapping("/find-similar")
    public ApiResponse<AiMatchingResponse> findSimilarItems(@RequestBody AiMatchingRequest request) {
        log.info("유사 습득물 찾기 요청: {}", request);

        AiMatchingResponse response = aiMatchingService.findSimilarItems(request);

        return ApiResponse.ok(response);
    }

    @GetMapping("/matched-items/{lostItemId}")
    public ApiResponse<AiMatchingResponse> getMatchedItems(@PathVariable Integer lostItemId) {
        log.info("매칭된 습득물 목록 조회: lostItemId={}", lostItemId);

        AiMatchingResponse response = aiMatchingService.getMatchedItems(lostItemId);

        return ApiResponse.ok(response);
    }
}