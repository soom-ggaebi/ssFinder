package com.ssfinder.domain.auth.service;

import com.ssfinder.domain.auth.dto.LoginResultType;
import com.ssfinder.domain.auth.dto.TokenPair;
import com.ssfinder.domain.auth.dto.request.KakaoLoginRequest;
import com.ssfinder.domain.auth.dto.request.RefreshTokenRequest;
import com.ssfinder.domain.auth.dto.response.KakaoLoginResponse;
import com.ssfinder.domain.notification.dto.request.FcmTokenRequest;
import com.ssfinder.domain.notification.service.FcmTokenService;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.repository.UserRepository;
import com.ssfinder.domain.user.service.UserService;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import com.ssfinder.global.converter.PhoneNumberEncryptConverter;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

/**
 * packageName    : com.ssfinder.domain.auth.service<br>
 * fileName       : AuthService.java<br>
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
@Transactional
@RequiredArgsConstructor
public class AuthService {
    private final UserRepository userRepository;
    private final TokenService tokenService;
    private final PhoneNumberEncryptConverter phoneNumberEncryptConverter;
    private final UserService userService;
    private final FcmTokenService fcmTokenService;

    @Value("${jwt.access-token-validity}")
    private long accessTokenValidity;

    public KakaoLoginResponse kakaoLoginOrRegister(KakaoLoginRequest kakaoLoginRequest) {
        // providerId로 기존 사용자 검색
        Optional<User> existingUserOpt = userRepository.findByProviderId(kakaoLoginRequest.providerId());

        User user;
        LoginResultType resultType;

        if (existingUserOpt.isPresent()) {
            resultType = LoginResultType.ALREADY_ACTIVE;
            User existingUser = existingUserOpt.get();

            if (existingUser.getDeletedAt() != null) {
                if (existingUser.isRecoverable()) { // 복구 가능
                    resultType = LoginResultType.RECOVERED;
                    existingUser.recover();
                } else { // 복구 불가능
                    resultType = LoginResultType.EXPIRED;
                    userRepository.delete(existingUser);
                    user = registerUser(kakaoLoginRequest);

                    // 토큰 발급 및 반환
                    TokenPair tokenPair = tokenService.generateTokens(user.getId());
                    return new KakaoLoginResponse(tokenPair.accessToken(), tokenPair.refreshToken(), accessTokenValidity, resultType);
                }
            }
            user = updateKakaoUserInfo(existingUser, kakaoLoginRequest);
        } else {
            resultType = LoginResultType.NEW_ACCOUNT;
            user = registerUser(kakaoLoginRequest);
        }

        // 토큰 발급
        TokenPair tokenPair = tokenService.generateTokens(user.getId());

        // fcm 토큰 저장
        fcmTokenService.registerOrUpdateFcmToken(user.getId(), new FcmTokenRequest(kakaoLoginRequest.fcmToken()));

        return new KakaoLoginResponse(tokenPair.accessToken(), tokenPair.refreshToken(), accessTokenValidity, resultType);
    }


    private User updateKakaoUserInfo(User existingUser, KakaoLoginRequest kakaoLoginRequest) {
        try {
            existingUser.setEmail(kakaoLoginRequest.email());
            return userRepository.save(existingUser);
        } catch (Exception e) {
            log.error("Error while updating kakao user info: {}", kakaoLoginRequest.email(), e);
            throw new CustomException(ErrorCode.USER_REGISTRATION_FAILED);
        }
    }

    private User registerUser(KakaoLoginRequest kakaoLoginRequest) {
        User user = kakaoLoginRequest.toUserEntity();

        // 전화번호 암호화 진행
        try {
            String encryptedPhoneNumber = phoneNumberEncryptConverter.convertToDatabaseColumn(kakaoLoginRequest.phoneNumber());
            user.setPhone(encryptedPhoneNumber);
        } catch (RuntimeException e) {
            throw new CustomException(ErrorCode.ENCRYPT_FAILED);
        }

        return userRepository.save(user);
    }

    public void logout(int userId) {
        tokenService.deleteRefreshToken(userId);
    }

    public TokenPair refreshAccessToken(RefreshTokenRequest refreshTokenRequest) {
        String refreshToken = refreshTokenRequest.refreshToken();

        // 리프레시 토큰 검증
        if (!tokenService.validateToken(refreshToken)) {
            throw new CustomException(ErrorCode.INVALID_TOKEN);
        }

        int userId = tokenService.getUserIdFromToken(refreshToken);

        // 탈퇴한 사용자인지 확인
        User user = userService.findUserById(userId);
        if (user.getDeletedAt() != null) {
            throw new CustomException(ErrorCode.USER_DELETED);
        }

        // Redis 저장된 값과 비교
        String storedRefreshToken = tokenService.getRefreshToken(userId);
        if (!refreshToken.equals(storedRefreshToken)) {
            throw new CustomException(ErrorCode.INVALID_REFRESH_TOKEN);
        }

        return tokenService.generateTokens(userId);
    }
}
