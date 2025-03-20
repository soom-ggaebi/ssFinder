package com.ssfinder.domain.auth.service;

import com.ssfinder.domain.auth.dto.TokenPair;
import com.ssfinder.domain.auth.dto.request.KakaoLoginRequest;
import com.ssfinder.domain.auth.dto.response.KakaoLoginResponse;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.repository.UserRepository;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import com.ssfinder.global.converter.PhoneNumberEncryptConverter;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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

    @Value("${jwt.access-token-validity}")
    private long accessTokenValidity;

    public KakaoLoginResponse kakaoLoginOrRegister(KakaoLoginRequest kakaoLoginRequest) {
        User user = userRepository.findByProviderId(kakaoLoginRequest.providerId())
                .map(existingUser -> updateKakaoUserInfo(existingUser, kakaoLoginRequest))
                .orElseGet(() -> registerUser(kakaoLoginRequest));

        // redis 토큰 발급
        TokenPair tokenPair = tokenService.generateTokens(user.getId());

        return new KakaoLoginResponse(tokenPair.accessToken(), tokenPair.refreshToken(), accessTokenValidity);
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
        String encryptedPhoneNumber = phoneNumberEncryptConverter.convertToDatabaseColumn(kakaoLoginRequest.phoneNumber());
        user.setPhone(encryptedPhoneNumber);

        return userRepository.save(user);
    }
}
