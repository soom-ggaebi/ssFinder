package com.ssfinder.domain.lostitem.controller;

import com.ssfinder.domain.lostitem.dto.request.LostItemRegisterRequest;
import com.ssfinder.domain.lostitem.dto.request.LostItemStatusUpdateRequest;
import com.ssfinder.domain.lostitem.dto.request.LostItemUpdateRequest;
import com.ssfinder.domain.lostitem.dto.request.UpdateNotificationSettingsRequest;
import com.ssfinder.domain.lostitem.dto.response.LostItemResponse;
import com.ssfinder.domain.lostitem.dto.response.LostItemStatusUpdateResponse;
import com.ssfinder.domain.lostitem.dto.response.LostItemUpdateResponse;
import com.ssfinder.domain.lostitem.dto.response.UpdateNotificationSettingsResponse;
import com.ssfinder.domain.lostitem.service.LostItemService;
import com.ssfinder.domain.user.dto.CustomUserDetails;
import com.ssfinder.global.common.response.ApiResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * packageName    : com.ssfinder.domain.lost.controller<br>
 * fileName       : LostController.java<br>
 * author         : joker901010<br>
 * date           : 2025-03-19<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          joker901010           최초생성<br>
 * 2025-03-27          joker901010           코드리뷰 수정<br>
 * <br>
 */
@RestController
@RequestMapping("/api/lost-items")
@RequiredArgsConstructor
public class LostItemController {

    private final LostItemService lostItemService;

    @GetMapping
    public ApiResponse<List<LostItemResponse>> getLostAll(@AuthenticationPrincipal CustomUserDetails userDetails) {
        List<LostItemResponse> lostItemList = lostItemService.getLostAll(userDetails.getUserId());
        return ApiResponse.ok(lostItemList);
    }

    @PostMapping
    public ApiResponse<LostItemResponse> registerLostItem(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                  @ModelAttribute @Valid LostItemRegisterRequest request) {
        LostItemResponse response = lostItemService.registerLostItem(userDetails.getUserId(), request);
        return ApiResponse.created(response);
    }

    @GetMapping("/{lostId}")
    public ApiResponse<LostItemResponse> getLostItem(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                     @PathVariable @Min(1) int lostId) {
        LostItemResponse response = lostItemService.getLostItem(userDetails.getUserId(), lostId);
        return ApiResponse.ok(response);
    }

    @PutMapping("/{lostId}")
    public ApiResponse<LostItemUpdateResponse> updateLostItem(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                              @PathVariable @Min(1) int lostId,
                                                              @ModelAttribute @Valid LostItemUpdateRequest request) {
        System.out.println(userDetails.getUserId());
        LostItemUpdateResponse response = lostItemService.updateLostItem(userDetails.getUserId(), lostId, request);
        return ApiResponse.ok(response);
    }

    @DeleteMapping("/{lostId}")
    public ApiResponse<?> deleteLostItem(@AuthenticationPrincipal CustomUserDetails userDetails,
                                         @PathVariable @Min(1) int lostId) {
        lostItemService.deleteLostItem(userDetails.getUserId(), lostId);
        return ApiResponse.noContent();
    }

    @PutMapping("/{lostId}/status")
    public ApiResponse<LostItemStatusUpdateResponse> updateLostItemStatus(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable @Min(1) int lostId,
            @Valid @RequestBody LostItemStatusUpdateRequest request) {
        LostItemStatusUpdateResponse response = lostItemService.updateLostItemStatus(userDetails.getUserId(), lostId, request);
        return ApiResponse.ok(response);
    }

    @PatchMapping("/{lostId}/notification-settings")
    public ApiResponse<UpdateNotificationSettingsResponse> updateNotificationSettings(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable @Min(1) int lostId,
            @Valid @RequestBody UpdateNotificationSettingsRequest request) {
        UpdateNotificationSettingsResponse response= lostItemService.updateNotificationSettings(userDetails.getUserId(), lostId, request);
        return ApiResponse.ok(response);

    }
}
