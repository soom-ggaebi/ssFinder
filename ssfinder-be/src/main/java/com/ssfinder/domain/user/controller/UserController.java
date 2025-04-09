package com.ssfinder.domain.user.controller;

import com.ssfinder.domain.user.dto.CustomUserDetails;
import com.ssfinder.domain.user.dto.request.UserUpdateRequest;
import com.ssfinder.domain.user.dto.response.UserGetResponse;
import com.ssfinder.domain.user.dto.response.UserUpdateResponse;
import com.ssfinder.domain.user.service.UserService;
import com.ssfinder.global.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

/**
 * packageName    : com.ssfinder.domain.user.controller<br>
 * fileName       : UserController.java<br>
 * author         : okeio<br>
 * date           : 2025-03-19<br>
 * description    : 사용자 정보 조회, 수정, 삭제를 처리하는 API 컨트롤러입니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          okeio           최초생성<br>
 * <br>
 */
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {
    private final UserService userService;

    /**
     * 인증된 사용자의 정보를 조회합니다.
     *
     * <p>
     * 이 메서드는 사용자의 ID를 기반으로 사용자 정보를 조회하여 반환합니다.
     * </p>
     *
     * @param userDetails 인증된 사용자 정보
     * @return 사용자 정보를 포함한 {@link ApiResponse}
     */
    @GetMapping
    public ApiResponse<UserGetResponse> getUser(@AuthenticationPrincipal CustomUserDetails userDetails) {
        UserGetResponse userGetResponse = userService.getUser(userDetails.getUserId());
        return ApiResponse.ok(userGetResponse);
    }

    /**
     * 인증된 사용자의 정보를 수정합니다.
     *
     * <p>
     * 이 메서드는 사용자 ID와 수정할 사용자 정보를 기반으로 사용자의 정보를 갱신합니다.
     * </p>
     *
     * @param userDetails 인증된 사용자 정보
     * @param userUpdateRequest 수정할 사용자 정보
     * @return 수정된 사용자 정보를 포함한 {@link ApiResponse}
     */
    @PutMapping
    public ApiResponse<UserUpdateResponse> updateUser(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                      @Valid @RequestBody UserUpdateRequest userUpdateRequest) {
        UserUpdateResponse userUpdateResponse = userService.updateUser(userDetails.getUserId(), userUpdateRequest);
        return ApiResponse.ok(userUpdateResponse);
    }

    /**
     * 인증된 사용자의 계정을 삭제합니다.
     *
     * <p>
     * 이 메서드는 사용자의 ID를 기반으로 사용자를 삭제하며, 관련된 리프레시 토큰도 함께 삭제합니다.
     * </p>
     *
     * @param userDetails 인증된 사용자 정보
     * @return HTTP 204 No Content 응답
     */
    @DeleteMapping
    public ApiResponse<?> deleteUser(@AuthenticationPrincipal CustomUserDetails userDetails) {
        userService.deleteUser(userDetails.getUserId());
        return ApiResponse.noContent();
    }
}
