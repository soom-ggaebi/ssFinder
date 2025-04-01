package com.ssfinder.domain.chat.dto.mapper;

import com.ssfinder.domain.chat.dto.response.MessageSendResponse;
import com.ssfinder.domain.chat.entity.ChatMessage;
import org.mapstruct.*;

/**
 * packageName    : com.ssfinder.domain.chat.dto.mapper<br>
 * fileName       : ChatMessageMapper.java<br>
 * author         : nature1216 <br>
 * date           : 2025-03-28<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-28          nature1216          최초생성<br>
 * <br>
 */
@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.WARN)
public interface ChatMessageMapper {
    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    @Mappings({
            @Mapping(source = "chatMessage.senderId", target = "userId"),
            @Mapping(source = "chatMessage.id", target = "messageId"),
            @Mapping(source = "nickname", target = "nickname")
    })
    MessageSendResponse mapToMessageSendResponse(ChatMessage chatMessage, String nickname);

}
