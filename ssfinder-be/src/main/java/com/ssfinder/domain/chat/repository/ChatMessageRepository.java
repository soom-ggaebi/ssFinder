package com.ssfinder.domain.chat.repository;

import com.ssfinder.domain.chat.entity.ChatMessage;
import org.springframework.data.mongodb.repository.MongoRepository;

/**
 * packageName    : com.ssfinder.domain.chat.repository<br>
 * fileName       : ChatMessageRepository.java<br>
 * author         : nature1216 <br>
 * date           : 2025-03-26<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-26          nature1216          최초생성<br>
 * <br>
 */
public interface ChatMessageRepository extends MongoRepository<ChatMessage, String> {

}
