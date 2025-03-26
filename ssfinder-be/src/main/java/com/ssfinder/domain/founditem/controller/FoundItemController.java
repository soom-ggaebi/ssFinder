package com.ssfinder.domain.founditem.controller;

import com.ssfinder.domain.founditem.dto.request.FoundItemRegisterRequest;
import com.ssfinder.domain.founditem.dto.request.FoundItemStatusUpdateRequest;
import com.ssfinder.domain.founditem.dto.request.FoundItemUpdateRequest;
import com.ssfinder.domain.founditem.dto.request.FoundItemViewportRequest;
import com.ssfinder.domain.founditem.dto.response.*;
import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.founditem.service.FoundItemBookmarkService;
import com.ssfinder.domain.founditem.service.FoundItemService;
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
@RequestMapping("/api/found-items")
@RequiredArgsConstructor
public class FoundItemController {

    private final FoundItemService foundItemService;
    private final FoundItemBookmarkService foundItemBookmarkService;

    @GetMapping
    public ApiResponse<List<FoundItemDetailResponse>> getFoundAll(@RequestBody FoundItemViewportRequest viewportRequest) {
        try {
            List<FoundItemDetailResponse> response = foundItemService.getFoundItemsByViewport(viewportRequest);
            return ApiResponse.ok(response);
        } catch (CustomException e) {
            throw e;
        } catch (Exception e) {
            throw new CustomException(ErrorCode.INTERNAL_SERVER_ERROR);
        }
    }

    @PostMapping
    public ApiResponse<?> RegisterFoundItem(@AuthenticationPrincipal CustomUserDetails userDetails,
                                            @RequestBody FoundItemRegisterRequest requestDTO){
        try {
            FoundItemRegisterResponse responseDTO = foundItemService.registerFoundItem(userDetails.getUserId(), requestDTO);
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
            FoundItemDetailResponse responseDTO = foundItemService.getFoundItemDetail(foundId);
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
            FoundItemUpdateResponse response = foundItemService.updateFoundItem(userDetails.getUserId(), foundId, updateRequest);
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
            foundItemService.deleteFoundItem(userDetails.getUserId(), foundId);
            return ApiResponse.ok("습득물 정보가 성공적으로 삭제되었습니다.");
        } catch (CustomException e) {
            throw e;
        } catch (Exception e) {
            throw new CustomException(ErrorCode.INTERNAL_SERVER_ERROR);
        }
    }

    @PutMapping("/{foundId}/status")
    public ApiResponse<FoundItemStatusUpdateResponse> updateFoundItemStatus(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                                            @PathVariable Integer foundId,
                                                                            @RequestBody FoundItemStatusUpdateRequest request) {
        try {
            FoundItemStatusUpdateResponse response = foundItemService.updateFoundItemStatus(userDetails.getUserId(), foundId, request);
            return ApiResponse.ok(response);
        } catch (CustomException e) {
            throw e;
        } catch (Exception e) {
            throw new CustomException(ErrorCode.INTERNAL_SERVER_ERROR);
        }
    }

    @GetMapping("/my-items")
    public ApiResponse<List<FoundItemDetailResponse>> getMyFoundItems(@AuthenticationPrincipal CustomUserDetails userDetails) {
        try {
            List<FoundItemDetailResponse> response = foundItemService.getMyFoundItems(userDetails.getUserId());
            return ApiResponse.ok(response);
        } catch (CustomException e) {
            throw e;
        } catch (Exception e) {
            throw new CustomException(ErrorCode.INTERNAL_SERVER_ERROR);
        }
    }


    @PostMapping("/{foundId}/bookmark")
    public ApiResponse<?> registerBookmark(@AuthenticationPrincipal CustomUserDetails userDetails,
                                           @PathVariable Integer foundId) {
        try {
            FoundItemBookmarkResponse response = foundItemBookmarkService.registerBookmark(userDetails.getUserId(), foundId);
            return ApiResponse.created(response);
        } catch (CustomException e) {
            throw e;
        } catch (Exception e) {
            throw new CustomException(ErrorCode.INTERNAL_SERVER_ERROR);
        }
    }

    @DeleteMapping("/bookmark/{bookmarkId}")
    public ApiResponse<?> deleteBookmark(@RequestAttribute("userDetails") CustomUserDetails userDetails,
                                         @PathVariable Integer bookmarkId) {
        try {
            foundItemBookmarkService.deleteBookmark(userDetails.getUserId(), bookmarkId);
            return ApiResponse.ok("북마크가 삭제되었습니다.");
        } catch (CustomException e) {
            throw e;
        } catch (Exception e) {
            throw new CustomException(ErrorCode.INTERNAL_SERVER_ERROR);
        }
    }

    @GetMapping("/bookmarks")
    public ApiResponse<?> getBookmarks(@RequestAttribute("userDetails") CustomUserDetails userDetails) {
        try {
            List<FoundItemBookmarkResponse> response = foundItemBookmarkService.getBookmarksByUser(userDetails.getUserId());
            return ApiResponse.ok(response);
        } catch (CustomException e) {
            throw e;
        } catch (Exception e) {
            throw new CustomException(ErrorCode.INTERNAL_SERVER_ERROR);
        }
    }
}
