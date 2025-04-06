package com.ssfinder.domain.chat.repository;

import com.ssfinder.domain.chat.entity.ChatRoom;
import com.ssfinder.domain.chat.entity.ChatRoomParticipant;
import com.ssfinder.domain.user.entity.User;
import io.lettuce.core.dynamic.annotation.Param;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

/**
 * packageName    : com.ssfinder.domain.chat.repository<br>
 * fileName       : UserChatRoomRepository.java<br>
 * author         : joker901010<br>
 * date           : 2025-03-19<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          joker901010           최초생성<br>
 * 2025-03-28          nature1216            findChatRoomParticipantByChatRoomAndUser 추가
 * 2025-04-01          nature1216            getChatRoomParticipantByChatRoomAndUserIsNot 추가
 * <br>
 */
public interface ChatRoomParticipantRepository extends JpaRepository<ChatRoomParticipant, Integer> {
    Optional<ChatRoomParticipant> findChatRoomParticipantByChatRoomAndUser(ChatRoom chatRoom, User user);

    ChatRoomParticipant getChatRoomParticipantByChatRoomAndUserIsNot(ChatRoom chatRoom, User user);
}
