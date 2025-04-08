package com.ssfinder.domain.notification.service;

import com.ssfinder.domain.notification.dto.request.FcmTokenRequest;
import com.ssfinder.domain.notification.entity.FcmToken;
import com.ssfinder.domain.notification.repository.FcmTokenRepository;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * packageName    : com.ssfinder.domain.notification.service<br>
 * fileName       : FcmTokenService.java<br>
 * author         : okeio<br>
 * date           : 2025-03-24<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-24          okeio           최초생성<br>
 * 2025-04-04          okeio           fcm 토큰 삭제 메서드 추가<br>
 * <br>
 */

@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class FcmTokenService {
    private final FcmTokenRepository fcmTokenRepository;
    private final UserService userService;

    public void registerOrUpdateFcmToken(int userId, FcmTokenRequest fcmTokenRequest) {
        User user = userService.findUserById(userId);
        String token = fcmTokenRequest.token();

        Optional<FcmToken> fcmTokenOpt = fcmTokenRepository.findByUserAndToken(user, token);

        if (fcmTokenOpt.isPresent()) {
            fcmTokenOpt.get().setUpdatedAt(LocalDateTime.now());
            log.info("Fcm token already exists with token: {}", token);
        } else {
            fcmTokenRepository.save(new FcmToken(token, user));
        }
    }

    public void deleteFcmTokenByUser(int userId, FcmTokenRequest fcmTokenRequest) {
        fcmTokenRepository.findByUserAndToken(userService.findUserById(userId), fcmTokenRequest.token())
                .ifPresent(fcmTokenRepository::delete);
    }

    public void deleteFcmToken(String token) {
        Optional<FcmToken> fcmTokenOpt = fcmTokenRepository.findByToken(token);
        fcmTokenOpt.ifPresent(fcmTokenRepository::delete);
    }

    @Transactional(readOnly = true)
    public List<String> getFcmTokens(Integer userId) {
        User user = userService.findUserById(userId);

        return fcmTokenRepository.findAllByUser(user)
                .stream()
                .map(FcmToken::getToken)
                .collect(Collectors.toList());
    }
}
