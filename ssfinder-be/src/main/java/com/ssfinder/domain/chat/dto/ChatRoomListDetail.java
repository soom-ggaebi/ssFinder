package com.ssfinder.domain.chat.dto;

import com.ssfinder.domain.chat.entity.ChatRoom;
import com.ssfinder.domain.chat.entity.ChatRoomParticipant;
import lombok.Builder;

/**
 * packageName    : com.ssfinder.domain.chat.dto<br>
 * fileName       : ChatRoomListDetail.java<br>
 * author         : nature1216 <br>
 * date           : 2025-04-07<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-07          nature1216          최초생성<br>
 * <br>
 */
@Builder
public record ChatRoomListDetail(
        ChatRoom chatRoom,
        ChatRoomParticipant chatRoomParticipant
) { }