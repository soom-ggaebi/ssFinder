package com.ssfinder.domain.chat.repository;

import com.ssfinder.domain.chat.dto.ChatRoomListDetail;
import com.ssfinder.domain.chat.entity.ChatRoom;
import io.lettuce.core.dynamic.annotation.Param;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

/**
 * packageName    : com.ssfinder.domain.chat.repository<br>
 * fileName       : ChatRoomRepository.java<br>
 * author         : joker901010<br>
 * date           : 2025-03-19<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          joker901010           최초생성<br>
 * <br>
 */
public interface ChatRoomRepository extends JpaRepository<ChatRoom, Integer> {
    @Query("SELECT cr " +
            "FROM ChatRoom cr " +
            "JOIN ChatRoomParticipant crp ON crp.chatRoom.id = cr.id " +
            "WHERE crp.user.id = :userId " +
            "AND cr.foundItem.id = :foundItemId")
    Optional<ChatRoom> findByUserAndFoundItem(@Param("userId") Integer userId,
                                              @Param("foundItemId") Integer foundItemId);

    @Query("SELECT new com.ssfinder.domain.chat.dto.ChatRoomListDetail(cr, crp) " +
            "FROM ChatRoom cr " +
            "JOIN ChatRoomParticipant crp ON crp.chatRoom.id = cr.id " +
            "WHERE crp.user.id = :userId " +
            "AND crp.status = 'ACTIVE'")
    List<ChatRoomListDetail> findByUserAndStatusIsActive(@Param("userId") Integer userId);
}
