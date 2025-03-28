package com.ssfinder.domain.chat.controller;

import com.ssfinder.domain.chat.service.ChatRoomService;
import com.ssfinder.domain.user.dto.CustomUserDetails;
import com.ssfinder.global.common.response.ApiResponse;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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
 * <br>
 */
@RestController
@RequestMapping("/api/chat-room")
@RequiredArgsConstructor
public class ChatRoomController {
    private final ChatRoomService chatRoomService;

    @PostMapping("/{foundItemId}")
    public ApiResponse<> getOrCreateChatRoom(@AuthenticationPrincipal CustomUserDetails userDetails,
                                        @NotNull @PathVariable Integer foundItemId) {
        Integer userId = userDetails.getUserId();

        chatRoomService.getOrCreateChatRoom(userId, foundItemId);

    }
}
