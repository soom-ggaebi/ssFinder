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
 * description    :  <br>
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

    @GetMapping
    public ApiResponse<UserGetResponse> getUser(@AuthenticationPrincipal CustomUserDetails userDetails) {
        UserGetResponse userGetResponse = userService.getUser(userDetails.getUserId());
        return ApiResponse.ok(userGetResponse);
    }

    @PutMapping
    public ApiResponse<UserUpdateResponse> updateUser(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                      @Valid @RequestBody UserUpdateRequest userUpdateRequest) {
        UserUpdateResponse userUpdateResponse = userService.updateUser(userDetails.getUserId(), userUpdateRequest);
        return ApiResponse.ok(userUpdateResponse);
    }

    @DeleteMapping
    public ApiResponse<?> deleteUser(@AuthenticationPrincipal CustomUserDetails userDetails) {
        userService.deleteUser(userDetails.getUserId());
        return ApiResponse.noContent();
    }

}
