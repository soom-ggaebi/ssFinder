package com.ssfinder.domain.chat.controller;

import com.ssfinder.domain.chat.dto.response.ActiveChatRoomListResponse;
import com.ssfinder.domain.chat.dto.request.ChatRoomNotificationEnabledRequest;
import com.ssfinder.domain.chat.dto.response.ChatRoomDetailResponse;
import com.ssfinder.domain.chat.dto.response.ChatRoomEntryResponse;
import com.ssfinder.domain.chat.service.ChatRoomService;
import com.ssfinder.domain.user.dto.CustomUserDetails;
import com.ssfinder.global.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * packageName    : com.ssfinder.domain.chat.controller<br>
 * fileName       : ChatController.java<br>
 * author         : joker901010<br>
 * date           : 2025-03-19<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          joker901010           최초생성<br>
 * 2025-03-31          nature1216            채팅방 생성, 상세정보 조회 메소드 추가
 * 2025-04-06          nature1216            채팅방 퇴장 메소드 추가
 * 2025-04-07          okeio                 채팅방 알림 설정 변경 추가
 * <br>
 */
@RestController
@RequestMapping("/api/chat-rooms")
@RequiredArgsConstructor
public class ChatRoomController {
    private final ChatRoomService chatRoomService;

    @PostMapping("/{foundItemId}")
    public ApiResponse<ChatRoomEntryResponse> getOrCreateChatRoom(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                                  @PathVariable Integer foundItemId) {
        Integer userId = userDetails.getUserId();

        ChatRoomEntryResponse response = chatRoomService.getOrCreateChatRoom(userId, foundItemId);

        return ApiResponse.ok(response);
    }

    @GetMapping("/{chatRoomId}/detail")
    public ApiResponse<ChatRoomDetailResponse> getChatRoomDetail(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                                 @PathVariable Integer chatRoomId) {
        Integer userId = userDetails.getUserId();

        ChatRoomDetailResponse response = chatRoomService.getChatRoomDetail(userId, chatRoomId);

        return ApiResponse.ok(response);
    }

    @GetMapping("/me")
    public ApiResponse<List<ActiveChatRoomListResponse>> getActiveChatRoomList(@AuthenticationPrincipal CustomUserDetails userDetails) {
        Integer userId = userDetails.getUserId();

        List<ActiveChatRoomListResponse> response = chatRoomService.getActiveChatRoomList(userId);
        return ApiResponse.ok(response);
    }

    @DeleteMapping("/{chatRoomId}/participants")
    public ApiResponse<Void> leave(@AuthenticationPrincipal CustomUserDetails userDetails,
                                   @PathVariable Integer chatRoomId) {
        Integer userId = userDetails.getUserId();
        chatRoomService.leave(userId, chatRoomId);

        return ApiResponse.noContent();
    }

    @PatchMapping("/{chatRoomId}/notification")
    public ApiResponse<Void> updateChatRoomNotificationsEnabled(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                                @PathVariable Integer chatRoomId,
                                                                @Valid @RequestBody ChatRoomNotificationEnabledRequest request) {
        Integer userId = userDetails.getUserId();
        chatRoomService.updateNotificationEnabled(userId, chatRoomId, request.isEnabled());

        return ApiResponse.noContent();
    }
}
