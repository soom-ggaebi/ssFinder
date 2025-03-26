package com.ssfinder.domain.lostitem.controller;

import com.ssfinder.domain.lostitem.dto.request.LostItemRegisterRequest;
import com.ssfinder.domain.lostitem.dto.response.LostItemResponse;
import com.ssfinder.domain.lostitem.entity.LostItem;
import com.ssfinder.domain.lostitem.service.LostItemService;
import com.ssfinder.domain.user.dto.CustomUserDetails;
import com.ssfinder.global.common.response.ApiResponse;
import jakarta.validation.Valid;
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
 * <br>
 */
@RestController
@RequestMapping("/api/lost")
@RequiredArgsConstructor
public class LostItemController {

    private final LostItemService lostItemService;

    @GetMapping
    public ApiResponse<List<LostItem>> getLostAll(@AuthenticationPrincipal CustomUserDetails userDetails) {
        List<LostItem> lostItemList = lostItemService.getLostAll(userDetails.getUserId());
        return ApiResponse.ok(lostItemList);
    }

    @PostMapping
    public ApiResponse<LostItem> registerLostItem(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                  @Valid @RequestBody LostItemRegisterRequest lostItemRegisterRequest){
        LostItem lostItem = lostItemService.registerLostItem(userDetails.getUserId(), lostItemRegisterRequest);
        return ApiResponse.created(lostItem);
    }

    @GetMapping("/{lostId}")
    public ApiResponse<?> getLostItem(@PathVariable int lostId) {
        LostItemResponse lostItemResponse = lostItemService.getLostItem(lostId);
        return ApiResponse.ok(lostItemResponse);
    }

    @DeleteMapping("/{lostId}")
    public ApiResponse<?> deleteLostItem(@PathVariable int lostId) {
        lostItemService.deleteLostItem(lostId);
        return ApiResponse.ok("분실물 정보가 성공적으로 삭제되었습니다.");
    }
}
