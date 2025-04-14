package com.ssfinder.domain.user.service;

import com.ssfinder.domain.auth.service.TokenService;
import com.ssfinder.domain.user.dto.CustomUserDetails;
import com.ssfinder.domain.user.dto.mapper.UserMapper;
import com.ssfinder.domain.user.dto.request.UserUpdateRequest;
import com.ssfinder.domain.user.dto.response.MyItemCountResponse;
import com.ssfinder.domain.user.dto.response.UserGetResponse;
import com.ssfinder.domain.user.dto.response.UserUpdateResponse;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.repository.UserRepository;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.user.service<br>
 * fileName       : UserService.java<br>
 * author         : okeio<br>
 * date           : 2025-03-19<br>
 * description    : 사용자 정보 조회, 수정, 삭제 및 인증 처리를 담당하는 서비스 클래스입니다.<br>
 *                  Spring Security의 {@link UserDetailsService}를 구현하여 인증을 지원합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          okeio           최초생성<br>
 * <br>
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class UserService implements UserDetailsService {
    private final UserRepository userRepository;
    private final UserMapper userMapper;
    private final TokenService tokenService;

    /**
     * 사용자 ID를 기반으로 {@link UserDetails}를 반환합니다. Spring Security 인증 과정에 사용됩니다.
     *
     * <p>
     * 이 메서드는 사용자의 ID를 기준으로 {@link UserDetails} 객체를 반환하며, 인증 및 권한 처리를 위해 사용됩니다.
     * </p>
     *
     * @param userId 사용자 ID (String)
     * @return 사용자 인증 정보 객체
     * @throws UsernameNotFoundException 사용자를 찾을 수 없는 경우 예외 발생
     */
    @Override
    public UserDetails loadUserByUsername(String userId) throws UsernameNotFoundException {
        User user = userRepository.findById(Integer.valueOf(userId))
                .orElseThrow(() -> new UsernameNotFoundException("User not found with userId: " + userId));

        return new CustomUserDetails(user.getId());
    }

    /**
     * 사용자 ID로 사용자 정보를 조회합니다.
     *
     * <p>
     * 이 메서드는 주어진 사용자 ID를 기반으로 사용자 정보를 조회하고, 사용자가 존재하지 않으면 예외를 발생시킵니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @return 사용자 엔티티
     * @throws CustomException USER_NOT_FOUND 예외
     */
    @Transactional(readOnly = true)
    public User findUserById(Integer userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new CustomException(ErrorCode.USER_NOT_FOUND));
    }

    /**
     * 사용자 ID를 기반으로 사용자 프로필 정보를 조회합니다.
     *
     * <p>
     * 이 메서드는 사용자 ID를 기반으로 사용자 프로필 정보를 조회하여 응답 DTO를 반환합니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @return 사용자 조회 응답 DTO
     */
    public UserGetResponse getUser(int userId) {
        User user = findUserById(userId);

        return userMapper.mapToUserGetResponse(user);
    }

    /**
     * 사용자 정보를 수정합니다.
     *
     * <p>
     * 이 메서드는 사용자 정보를 수정하며, 주어진 요청 DTO를 기반으로 사용자의 프로필을 업데이트합니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @param userUpdateRequest 사용자 수정 요청 DTO
     * @return 수정된 사용자 정보 응답 DTO
     */
    public UserUpdateResponse updateUser(int userId, UserUpdateRequest userUpdateRequest) {
        User user = findUserById(userId);

        userMapper.updateUserFromRequest(userUpdateRequest, user);

        return userMapper.mapToUserUpdateResponse(user);
    }

    /**
     * 사용자 계정을 탈퇴 처리합니다. deletedAt을 설정하고, 토큰을 만료시킵니다.
     *
     * <p>
     * 이 메서드는 사용자가 탈퇴 요청 시 계정을 삭제하고, 해당 사용자의 리프레시 토큰을 삭제하여 인증을 만료시킵니다.
     * </p>
     *
     * @param userId 사용자 ID
     */
    public void deleteUser(int userId) {
        User user = findUserById(userId);
        user.setDeletedAt(LocalDateTime.now());

        tokenService.deleteRefreshToken(userId);
    }

    /**
     * 프록시 조회용 getReferenceById (lazy fetch용).
     *
     * <p>
     * 이 메서드는 프록시 조회를 위해 사용되며, 실제 데이터를 즉시 로드하지 않고, 필요한 시점에 데이터를 가져옵니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @return 프록시 형태의 User 엔티티
     */
    public User getReferenceById(int userId) {
        return userRepository.getReferenceById(userId);
    }

    @Transactional(readOnly = true)
    public MyItemCountResponse getMyItemCounts(int userId) {
        MyItemCountResponse response = userRepository.countItemsByUserId(userId);
        return MyItemCountResponse.builder()
                .lostItemCount(response.getLostItemCount())
                .foundItemCount(response.getFoundItemCount())
                .build();
    }
}
