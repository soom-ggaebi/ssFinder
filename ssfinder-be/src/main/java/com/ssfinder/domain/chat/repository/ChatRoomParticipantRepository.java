package com.ssfinder.domain.chat.repository;

import com.ssfinder.domain.chat.entity.ChatRoom;
import com.ssfinder.domain.chat.entity.ChatRoomParticipant;
import com.ssfinder.domain.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

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
 * <br>
 */
public interface ChatRoomParticipantRepository extends JpaRepository<ChatRoomParticipant, Integer> {
    List<ChatRoomParticipant> findChatRoomParticipantByChatRoomAndUser(ChatRoom chatRoom, User user);

    List<ChatRoomParticipant> findChatRoomParticipantsByFoundItemAnd
}
