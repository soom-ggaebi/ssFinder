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
 * description    : 사용자별 FCM 토큰의 등록, 갱신, 삭제, 조회를 처리하는 서비스입니다.<br>
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

    /**
     * FCM 토큰을 등록하거나 이미 존재하는 경우 마지막 갱신 시간을 업데이트합니다.
     *
     * <p>
     * 사용자의 ID와 전달받은 토큰이 이미 존재하는지 확인한 뒤,
     * 존재하면 `updatedAt` 필드를 현재 시간으로 갱신하고,
     * 존재하지 않으면 새로 등록합니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @param fcmTokenRequest 등록 또는 갱신할 FCM 토큰 요청 정보
     */
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

    /**
     * 사용자 ID와 토큰 정보를 기준으로 해당 FCM 토큰을 삭제합니다.
     *
     * <p>
     * 사용자의 FCM 토큰 목록 중 전달받은 토큰과 일치하는 항목이 있으면 삭제합니다.
     * 보통 로그아웃이나 수동 해제 시 사용됩니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @param fcmTokenRequest 삭제할 FCM 토큰 요청 정보
     */
    public void deleteFcmTokenByUser(int userId, FcmTokenRequest fcmTokenRequest) {
        fcmTokenRepository.findByUserAndToken(userService.findUserById(userId), fcmTokenRequest.token())
                .ifPresent(fcmTokenRepository::delete);
    }

    /**
     * FCM 토큰 문자열을 기준으로 해당 토큰을 삭제합니다.
     *
     * <p>
     * 일반적으로 FCM 메시지 전송 실패 시, 유효하지 않은 토큰을 정리할 때 사용됩니다.
     * </p>
     *
     * @param token 삭제할 FCM 토큰 문자열
     */
    public void deleteFcmToken(String token) {
        List<FcmToken> fcmTokens = fcmTokenRepository.findByToken(token);
        if (!fcmTokens.isEmpty()) {
            fcmTokenRepository.deleteAll(fcmTokens);
            log.info("총 {}개의 FCM 토큰 삭제 완료: {}", fcmTokens.size(), token);
        } else {
            log.info("삭제할 FCM 토큰이 없음: {}", token);
        }
    }

    /**
     * 특정 사용자의 모든 FCM 토큰 문자열 목록을 조회합니다.
     *
     * <p>
     * 사용자가 로그인한 모든 기기에서 등록된 FCM 토큰을 조회하여,
     * 푸시 알림을 다중 디바이스로 전송할 수 있게 합니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @return 사용자의 FCM 토큰 문자열 리스트
     */
    @Transactional(readOnly = true)
    public List<String> getFcmTokens(Integer userId) {
        User user = userService.findUserById(userId);

        return fcmTokenRepository.findAllByUser(user)
                .stream()
                .map(FcmToken::getToken)
                .collect(Collectors.toList());
    }
}
