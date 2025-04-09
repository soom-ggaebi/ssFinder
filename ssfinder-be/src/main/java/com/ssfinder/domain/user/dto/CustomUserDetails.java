package com.ssfinder.domain.user.dto;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;

/**
 * packageName    : com.ssfinder.domain.user.dto<br>
 * fileName       : CustomUserDetails.java<br>
 * author         : okeio<br>
 * date           : 2025-03-19<br>
 * description    : Spring Security의 {@link UserDetails}를 구현한 사용자 인증 객체입니다.<br>
 *                  인증된 사용자의 userId만을 보유하며, 기타 필드는 사용하지 않습니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19         okeio           최초생성<br>
 * <br>
 */
public class CustomUserDetails implements UserDetails {

    private final int userId;

    public CustomUserDetails(int userId) {
        this.userId = userId;
    }

    public int getUserId() {
        return userId;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return null;
    }

    @Override
    public String getPassword() {
        return null;
    }

    @Override
    public String getUsername() {
        return String.valueOf(userId);
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return true;
    }
}
