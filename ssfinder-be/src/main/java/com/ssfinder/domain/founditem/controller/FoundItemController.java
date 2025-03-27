package com.ssfinder.domain.founditem.controller;

import com.ssfinder.domain.founditem.dto.request.FoundItemRegisterRequest;
import com.ssfinder.domain.founditem.dto.request.FoundItemStatusUpdateRequest;
import com.ssfinder.domain.founditem.dto.request.FoundItemUpdateRequest;
import com.ssfinder.domain.founditem.dto.request.FoundItemViewportRequest;
import com.ssfinder.domain.founditem.dto.response.*;
import com.ssfinder.domain.founditem.service.FoundItemBookmarkService;
import com.ssfinder.domain.founditem.service.FoundItemService;
import com.ssfinder.domain.user.dto.CustomUserDetails;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import com.ssfinder.global.common.response.ApiResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.util.List;

/**
 * packageName    : com.ssfinder.domain.found.controller<br>
 * fileName       : FoundController.java<br>
 * author         : joker901010<br>
 * date           : 2025-03-19<br>
 * description    :  습득물 관련 API<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          joker901010           최초생성<br>
 * 2025-03-27          joker901010           코드리뷰 수정<br>
 * <br>
 */
@RestController
@RequestMapping("/api/found-items")
@RequiredArgsConstructor
public class FoundItemController {

    private final FoundItemService foundItemService;
    private final FoundItemBookmarkService foundItemBookmarkService;

    @GetMapping
    public ApiResponse<List<FoundItemDetailResponse>> getFoundAll(@Valid @RequestBody FoundItemViewportRequest viewportRequest) {
        List<FoundItemDetailResponse> response = foundItemService.getFoundItemsByViewport(viewportRequest);
        return ApiResponse.ok(response);
    }

    @PostMapping
    public ApiResponse<?> RegisterFoundItem(@AuthenticationPrincipal CustomUserDetails userDetails,
                                            @ModelAttribute @Valid FoundItemRegisterRequest requestDTO){
        FoundItemRegisterResponse responseDTO = foundItemService.registerFoundItem(userDetails.getUserId(), requestDTO);
        return ApiResponse.created(responseDTO);
    }

    @GetMapping("/{foundId}")
    public ApiResponse<FoundItemDetailResponse> getFoundItem(@PathVariable @Min(1) int foundId) {
        FoundItemDetailResponse responseDTO = foundItemService.getFoundItemDetail(foundId);
        return ApiResponse.ok(responseDTO);
    }

    @PutMapping("/{foundId}")
    public ApiResponse<?> updateFoundItem(@AuthenticationPrincipal CustomUserDetails userDetails,
                                          @PathVariable @Min(1) int foundId,
                                          @ModelAttribute @Valid FoundItemUpdateRequest updateRequest) throws IOException {
        FoundItemUpdateResponse response = foundItemService.updateFoundItem(userDetails.getUserId(), foundId, updateRequest);
        return ApiResponse.ok(response);
    }

    @DeleteMapping("/{foundId}")
    public ApiResponse<?> deleteFoundItem(@AuthenticationPrincipal CustomUserDetails userDetails,
                                          @PathVariable @Min(1) int foundId) {
        foundItemService.deleteFoundItem(userDetails.getUserId(), foundId);
        return ApiResponse.noContent();
    }

    @PutMapping("/{foundId}/status")
    public ApiResponse<FoundItemStatusUpdateResponse> updateFoundItemStatus(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                                            @PathVariable @Min(1) int foundId,
                                                                            @Valid @RequestBody FoundItemStatusUpdateRequest request) {
        FoundItemStatusUpdateResponse response = foundItemService.updateFoundItemStatus(userDetails.getUserId(), foundId, request);
        return ApiResponse.ok(response);
    }

    @GetMapping("/my-items")
    public ApiResponse<List<FoundItemDetailResponse>> getMyFoundItems(@AuthenticationPrincipal CustomUserDetails userDetails) {
        List<FoundItemDetailResponse> response = foundItemService.getMyFoundItems(userDetails.getUserId());
        return ApiResponse.ok(response);
    }


    @PostMapping("/{foundId}/bookmark")
    public ApiResponse<?> registerBookmark(@AuthenticationPrincipal CustomUserDetails userDetails,
                                           @PathVariable @Min(1) int foundId) {
        FoundItemBookmarkResponse response = foundItemBookmarkService.registerBookmark(userDetails.getUserId(), foundId);
        return ApiResponse.created(response);
    }

    @DeleteMapping("/bookmark/{bookmarkId}")
    public ApiResponse<?> deleteBookmark(@RequestAttribute("userDetails") CustomUserDetails userDetails,
                                         @PathVariable @Min(1) int bookmarkId) {
        foundItemBookmarkService.deleteBookmark(userDetails.getUserId(), bookmarkId);
        return ApiResponse.noContent();
    }

    @GetMapping("/bookmarks")
    public ApiResponse<?> getBookmarks(@RequestAttribute("userDetails") CustomUserDetails userDetails) {
        List<FoundItemBookmarkResponse> response = foundItemBookmarkService.getBookmarksByUser(userDetails.getUserId());
        return ApiResponse.ok(response);
    }
}
