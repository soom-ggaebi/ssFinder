package com.ssfinder.domain.notification.service;

import com.ssfinder.domain.notification.dto.request.FcmTokenRequest;
import com.ssfinder.domain.notification.entity.FcmToken;
import com.ssfinder.domain.notification.repository.FcmTokenRepository;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

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
 * <br>
 */

@Service
@Transactional
@RequiredArgsConstructor
public class FcmTokenService {
    private final FcmTokenRepository fcmTokenRepository;
    private final UserService userService;

    public void registerFcmToken(int userId, FcmTokenRequest fcmTokenRequest) {
        User user = userService.findUserById(userId);
        String token = fcmTokenRequest.token();

        Optional<FcmToken> fcmTokenOpt = fcmTokenRepository.findByUserAndFcmToken(user, token);

        if (fcmTokenOpt.isPresent()) {
            fcmTokenOpt.get().setUpdatedAt(LocalDateTime.now());
        } else {
            fcmTokenRepository.save(new FcmToken(token, user));
        }
    }

    public void deleteFcmToken(int userId, FcmTokenRequest fcmTokenRequest) {
        User user = userService.findUserById(userId);
        String token = fcmTokenRequest.token();

        Optional<FcmToken> fcmTokenOpt = fcmTokenRepository.findByUserAndFcmToken(user, token);

        fcmTokenOpt.ifPresent(fcmTokenRepository::delete);
    }
}
