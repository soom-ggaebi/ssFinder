package com.ssfinder.domain.founditem.controller;

import com.ssfinder.domain.founditem.dto.request.*;
import com.ssfinder.domain.founditem.dto.response.*;
import com.ssfinder.domain.founditem.entity.FoundItemDocument;
import com.ssfinder.domain.founditem.service.FoundItemBookmarkService;
import com.ssfinder.domain.founditem.service.FoundItemService;
import com.ssfinder.domain.user.dto.CustomUserDetails;
import com.ssfinder.global.common.response.ApiResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.CompletableFuture;

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

    @GetMapping("/view")
    public ApiResponse<SearchAfterPageResponse<FoundItemDocumentDetailResponse>> getFoundAll(
            @Valid @RequestBody FoundItemViewportRequest viewportRequest,
            @RequestParam(value = "pageSize", defaultValue = "10") int pageSize,
            @RequestParam(value = "searchAfter", required = false) List<Object> searchAfterList) {

        Object[] searchAfter = (searchAfterList != null) ? searchAfterList.toArray() : null;
        SearchAfterPageResponse<FoundItemDocumentDetailResponse> response =
                foundItemService.getFoundItemsByViewport(viewportRequest, searchAfter, pageSize);
        return ApiResponse.ok(response);
    }

    @PostMapping
    public ApiResponse<?> RegisterFoundItem(@AuthenticationPrincipal CustomUserDetails userDetails,
                                            @ModelAttribute @Valid FoundItemRegisterRequest request){
        FoundItemDocument response = foundItemService.registerFoundItem(userDetails.getUserId(), request);
        return ApiResponse.created(response);
    }

    @GetMapping("/{foundId}")
    public ApiResponse<FoundItemDocumentDetailResponse> getFoundItem(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                                     @PathVariable @Min(1) int foundId) {
        Integer userId = (userDetails != null) ? userDetails.getUserId() : null;

        FoundItemDocumentDetailResponse responseDTO = foundItemService.getFoundItemDetail(userId, foundId);
        return ApiResponse.ok(responseDTO);
    }

    @PutMapping("/{foundId}")
    public ApiResponse<?> updateFoundItem(@AuthenticationPrincipal CustomUserDetails userDetails,
                                          @PathVariable @Min(1) int foundId,
                                          @ModelAttribute @Valid FoundItemUpdateRequest updateRequest) {
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
    public ApiResponse<FoundItemDocumentDetailResponse> updateFoundItemStatus(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                                            @PathVariable @Min(1) int foundId,
                                                                            @Valid @RequestBody FoundItemStatusUpdateRequest request) {
        FoundItemDocumentDetailResponse response = foundItemService.updateFoundItemStatus(userDetails.getUserId(), foundId, request);
        return ApiResponse.ok(response);
    }

    @GetMapping("/my-items")
    public ApiResponse<Page<FoundItemDetailResponse>> getMyFoundItems(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                                      @RequestParam(defaultValue = "0") int page,
                                                                      @RequestParam(defaultValue = "10") int size,
                                                                      @RequestParam(defaultValue = "createdAt") String sortBy,
                                                                      @RequestParam(defaultValue = "desc") String sortDirection) {
        Sort.Direction direction = sortDirection.equalsIgnoreCase("asc") ?
                Sort.Direction.ASC : Sort.Direction.DESC;

        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        Page<FoundItemDetailResponse> response = foundItemService.getMyFoundItems(userDetails.getUserId(), pageable);
        return ApiResponse.ok(response);
    }

    @GetMapping("/viewport/coordinates")
    public CompletableFuture<ApiResponse<List<FoundItemClusterResponse>>> findViewportCoordinatesForClustering(
            @Valid @RequestBody FoundItemViewportRequest request) {
        return foundItemService.getCoordinatesInViewportForClusteringAsync(request)
                .thenApply(ApiResponse::ok);
    }

    @GetMapping("/viewport")
    public ApiResponse<Page<FoundItemSummaryResponse>> findPagedFoundItemsInViewport(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody FoundItemViewportRequest request,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "created_at") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDirection) {

        Integer userId = (userDetails != null) ? userDetails.getUserId() : null;

        Sort.Direction direction = sortDirection.equalsIgnoreCase("asc") ?
                Sort.Direction.ASC : Sort.Direction.DESC;

        PageRequest pageRequest = PageRequest.of(page, size, Sort.by(direction, sortBy));

        Page<FoundItemSummaryResponse> response = foundItemService.getPagedFoundItemsInViewport(userId, request, pageRequest);

        return ApiResponse.ok(response);
    }

    @GetMapping("/filter")
    public CompletableFuture<ApiResponse<List<FoundItemClusterResponse>>> getFilteredFoundItems(
            @Valid @RequestBody FoundItemFilterRequest request) {
        return foundItemService.getFilteredFoundItemsAsync(request)
                .thenApply(ApiResponse::ok);
    }

    @GetMapping("/cluster/detail")
    public ApiResponse<Page<FoundItemSummaryResponse>> getClusterDetailInfo(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody FoundItemClusterRequest request,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "created_at") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDirection) {

        Integer userId = (userDetails != null) ? userDetails.getUserId() : null;

        Sort.Direction direction = sortDirection.equalsIgnoreCase("asc") ?
                Sort.Direction.ASC : Sort.Direction.DESC;

        PageRequest pageRequest = PageRequest.of(page, size, Sort.by(direction, sortBy));

        Page<FoundItemSummaryResponse> response = foundItemService.getClusterDetailItems(
                userId, request.getIds(), pageRequest);

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
