package com.ssfinder.domain.chat.controller;

import com.ssfinder.domain.chat.dto.request.MessageSendRequest;
import com.ssfinder.domain.chat.service.ChatService;
import com.ssfinder.global.util.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.stereotype.Controller;

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
@Controller
@RequiredArgsConstructor
public class ChattingController {
    private final ChatService chatService;

    @MessageMapping("/chat-room/send/{chatRoomId}")
    public void send(@Payload MessageSendRequest request,
                     @DestinationVariable Integer chatRoomId/*,
                     SimpMessageHeaderAccessor accessor*/) {
        chatService.send(1, chatRoomId, request);
    }
}
