package com.ssfinder.domain.user.dto.mapper;

import com.ssfinder.domain.user.dto.request.UserUpdateRequest;
import com.ssfinder.domain.user.dto.response.UserGetResponse;
import com.ssfinder.domain.user.dto.response.UserUpdateResponse;
import com.ssfinder.domain.user.entity.User;
import org.mapstruct.*;

/**
 * packageName    : com.ssfinder.domain.user.mapper<br>
 * fileName       : UserMapper.java<br>
 * author         : okeio<br>
 * date           : 2025-03-20<br>
 * description    : User 엔티티와 DTO 간의 변환을 담당하는 MapStruct 매퍼 인터페이스입니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-20          okeio           최초생성<br>
 * <br>
 */
@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.WARN)
public interface UserMapper {

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    void updateUserFromRequest(UserUpdateRequest request, @MappingTarget User user);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    UserUpdateResponse mapToUserUpdateResponse(User user);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    UserGetResponse mapToUserGetResponse(User user);
}
