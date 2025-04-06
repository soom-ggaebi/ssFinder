package com.ssfinder.domain.chat.controller;

import com.ssfinder.domain.chat.dto.kafka.KafkaChatMessage;
import com.ssfinder.domain.chat.dto.request.MessageSendRequest;
import com.ssfinder.domain.chat.service.ChatService;
import com.ssfinder.domain.user.dto.CustomUserDetails;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.*;
import org.springframework.messaging.simp.annotation.SendToUser;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.security.Principal;

/**
 * packageName    : com.ssfinder.domain.chat.controller<br>
 * fileName       : ChattingController.java<br>
 * author         : nature1216 <br>
 * date           : 2025-03-25<br>
 * description    : 채팅 기능을 처리하는 websocket 컨트롤러입니다. stomp 메세지를 처리합니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-25          nature1216          최초생성<br>
 * <br>
 */
@Slf4j
@Controller
@RequestMapping("/api/chat-rooms")
@RequiredArgsConstructor
public class ChattingController {
    private final ChatService chatService;

    public static final String PART_CHAT_IMAGE = "image";

    @MessageMapping("chat-room/{chatRoomId}")
    public void send(@Valid @Payload MessageSendRequest request,
                     @DestinationVariable Integer chatRoomId,
                     Principal principal) {
        Integer userId = Integer.parseInt(principal.getName());
        chatService.send(userId, chatRoomId, request);
    }

    @MessageExceptionHandler(CustomException.class)
    @SendToUser("/queue/errors")
    public ApiResponse<Void> handleCustomException(CustomException e) {
        return ApiResponse.fail(e);
    }

    @PostMapping("/{chatRoomId}/upload")
    @ResponseBody
    public ApiResponse<KafkaChatMessage> sendFile(@AuthenticationPrincipal CustomUserDetails userDetails,
                                   @PathVariable Integer chatRoomId,
                                   @RequestPart(name = PART_CHAT_IMAGE, required = false) MultipartFile image) {
        Integer userId = userDetails.getUserId();
        KafkaChatMessage response = chatService.sendFile(userId, chatRoomId, image);
        return ApiResponse.ok(response);
    }
}
