package com.ssfinder.domain.found.controller;

import com.ssfinder.domain.found.dto.request.FoundItemRegisterRequest;
import com.ssfinder.domain.found.dto.request.FoundItemUpdateRequest;
import com.ssfinder.domain.found.dto.response.FoundItemDetailResponse;
import com.ssfinder.domain.found.dto.response.FoundItemRegisterResponse;
import com.ssfinder.domain.found.dto.response.FoundItemUpdateResponse;
import com.ssfinder.domain.found.entity.FoundItem;
import com.ssfinder.domain.found.service.FoundService;
import com.ssfinder.domain.user.dto.CustomUserDetails;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import com.ssfinder.global.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * packageName    : com.ssfinder.domain.found.controller<br>
 * fileName       : FoundController.java<br>
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
@RequestMapping("/api/found")
@RequiredArgsConstructor
public class FoundController {

    private final FoundService foundService;

    @GetMapping
    public ApiResponse<List<FoundItem>> getLostAll() {
        List<FoundItem> foundItemList = foundService.getLostAll();

        return ApiResponse.ok(foundItemList);
    }

    @PostMapping
    public ApiResponse<?> RegisterFoundItem(@AuthenticationPrincipal CustomUserDetails userDetails,
                                            @RequestBody FoundItemRegisterRequest requestDTO){
        try {
            FoundItemRegisterResponse responseDTO = foundService.registerFoundItem(userDetails.getUserId(), requestDTO);
            return ApiResponse.created(responseDTO);
        } catch (IllegalAccessError e) {
            throw new CustomException(ErrorCode.INVALID_INPUT_VALUE);
        } catch (Exception e) {
            throw new CustomException(ErrorCode.INTERNAL_SERVER_ERROR);
        }
    }

    @GetMapping("/{foundId}")
    public ApiResponse<FoundItemDetailResponse> getFoundItem(@PathVariable int foundId) {
        try {
            FoundItemDetailResponse responseDTO = foundService.getFoundItemDetail(foundId);
            return ApiResponse.ok(responseDTO);
        } catch (CustomException  e) {
            throw e;
        } catch (Exception e) {
            throw new CustomException(ErrorCode.INTERNAL_SERVER_ERROR);
        }
    }

    @PutMapping("/{foundId}")
    public ApiResponse<?> updateFoundItem(@AuthenticationPrincipal CustomUserDetails userDetails,
                                          @PathVariable Integer foundId,
                                          @RequestBody FoundItemUpdateRequest updateRequest) {
        try {
            FoundItemUpdateResponse response = foundService.updateFoundItem(userDetails.getUserId(), foundId, updateRequest);
            return ApiResponse.ok(response);
        } catch (CustomException e) {
            throw e;
        } catch (Exception e) {
            throw new CustomException(ErrorCode.INTERNAL_SERVER_ERROR);
        }
    }

    @DeleteMapping("/{foundId}")
    public ApiResponse<?> deleteFoundItem(@AuthenticationPrincipal CustomUserDetails userDetails,
                                          @PathVariable Integer foundId) {
        try {
            foundService.deleteFoundItem(userDetails.getUserId(), foundId);
            return ApiResponse.ok("습득물 정보가 성공적으로 삭제되었습니다.");
        } catch (CustomException e) {
            throw e;
        } catch (Exception e) {
            throw new CustomException(ErrorCode.INTERNAL_SERVER_ERROR);
        }
    }
}
