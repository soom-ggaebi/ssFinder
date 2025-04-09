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
 * description    : 카카오 로그인, 로그아웃, 토큰 재발급 등의 인증 관련 비즈니스 로직을 처리하는 서비스 클래스입니다.<br>
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

    /**
     * 카카오 로그인을 처리하거나 신규 회원을 등록합니다.
     *
     * <p>
     * providerId를 기준으로 기존 사용자를 조회하고, 삭제된 사용자는 복구 여부에 따라 처리합니다.
     * 신규 사용자 등록 또는 기존 사용자 정보 업데이트 후, 토큰을 발급하여 응답합니다.
     * </p>
     *
     * @param kakaoLoginRequest 카카오 로그인 요청 정보
     * @return 액세스 토큰, 리프레시 토큰, 만료 시간, 로그인 결과를 포함한 {@link KakaoLoginResponse}
     */
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

    /**
     * 기존 사용자의 이메일 정보를 갱신합니다.
     *
     * <p>
     * 사용자 정보를 수정한 뒤 저장하며, 실패 시 예외를 발생시킵니다.
     * </p>
     *
     * @param existingUser 기존 사용자 엔티티
     * @param kakaoLoginRequest 카카오 로그인 요청 정보
     * @return 갱신된 사용자 엔티티
     */
    private User updateKakaoUserInfo(User existingUser, KakaoLoginRequest kakaoLoginRequest) {
        try {
            existingUser.setEmail(kakaoLoginRequest.email());
            return userRepository.save(existingUser);
        } catch (Exception e) {
            log.error("Error while updating kakao user info: {}", kakaoLoginRequest.email(), e);
            throw new CustomException(ErrorCode.USER_REGISTRATION_FAILED);
        }
    }

    /**
     * 카카오 로그인 요청을 기반으로 새 사용자 계정을 등록합니다.
     *
     * <p>
     * 전화번호는 암호화하여 저장되며, 실패 시 예외를 발생시킵니다.
     * </p>
     *
     * @param kakaoLoginRequest 카카오 로그인 요청 정보
     * @return 저장된 사용자 엔티티
     */
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

    /**
     * 사용자 로그아웃을 처리합니다.
     *
     * <p>
     * 사용자 ID를 기반으로 저장된 리프레시 토큰을 삭제합니다.
     * </p>
     *
     * @param userId 로그아웃할 사용자 ID
     */
    public void logout(int userId) {
        tokenService.deleteRefreshToken(userId);
    }

    /**
     * 리프레시 토큰을 이용하여 새로운 액세스 토큰과 리프레시 토큰을 발급합니다.
     *
     * <p>
     * 토큰 유효성 검증, 사용자 존재 여부 확인, Redis에 저장된 리프레시 토큰 일치 여부 등을 체크합니다.
     * </p>
     *
     * @param refreshTokenRequest 리프레시 토큰 요청 정보
     * @return 새로 발급된 {@link TokenPair}
     */
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
