package com.ssfinder.domain.chat.repository;

import com.ssfinder.domain.chat.entity.UserChatRoom;
import org.springframework.data.jpa.repository.JpaRepository;

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
public interface UserChatRoomRepository extends JpaRepository<UserChatRoom, Integer> {
}
