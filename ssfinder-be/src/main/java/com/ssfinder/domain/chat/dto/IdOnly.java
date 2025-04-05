package com.ssfinder.domain.chat.dto;

import org.bson.types.ObjectId;
import org.springframework.data.mongodb.core.mapping.Field;

/**
 * packageName    : com.ssfinder.domain.chat.dto<br>
 * fileName       : IdOnly.java<br>
 * author         : nature1216 <br>
 * date           : 2025-04-05<br>
 * description    : mongodb ObjectId 핸들링을 위한 dto입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-31          nature1216          최초생성<br>
 * <br>
 */
public record IdOnly (
        @Field("_id") ObjectId id
) {
}
