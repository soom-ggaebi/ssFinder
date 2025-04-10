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
 * description    :  <br>
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

    @Override
    public UserDetails loadUserByUsername(String userId) throws UsernameNotFoundException {
        User user = userRepository.findById(Integer.valueOf(userId))
                .orElseThrow(() -> new UsernameNotFoundException("User not found with userId: " + userId));

        return new CustomUserDetails(user.getId());
    }

    @Transactional(readOnly = true)
    public User findUserById(Integer userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new CustomException(ErrorCode.USER_NOT_FOUND));
    }

    public UserGetResponse getUser(int userId) {
        User user = findUserById(userId);

        return userMapper.mapToUserGetResponse(user);
    }

    public UserUpdateResponse updateUser(int userId, UserUpdateRequest userUpdateRequest) {
        User user = findUserById(userId);

        userMapper.updateUserFromRequest(userUpdateRequest, user);

        return userMapper.mapToUserUpdateResponse(user);
    }

    public void deleteUser(int userId) {
        User user = findUserById(userId);
        user.setDeletedAt(LocalDateTime.now());

        tokenService.deleteRefreshToken(userId);
    }

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
