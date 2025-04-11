package com.ssfinder.global.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ssfinder.domain.user.service.UserService;
import com.ssfinder.global.common.filter.JwtAuthenticationFilter;
import com.ssfinder.global.util.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.annotation.web.configurers.CsrfConfigurer;
import org.springframework.security.config.annotation.web.configurers.HttpBasicConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.Collections;

/**
 * packageName    : com.ssfinder.global.config<br>
 * fileName       : SecurityConfig.java<br>
 * author         : okeio<br>
 * date           : 2025-03-20<br>
 * description    : Spring Security 설정을 담당하는 구성 클래스입니다.<br>
 <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-20          okeio           최초생성<br>
 */
@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {
    public static final String[] allowUrls = {
            "/", "/api/auth/**", "/swagger-ui/**", "/swagger-ui.html",
            "/v3/api-docs/**", "/swagger-resources/**", "/error",
            "/agarang", "/ws/**", "/app/**", "/api/found-items/filter",
            "/api/found-items/viewport/coordinates", "/api/found-items/viewport",
            "/api/found-items/{foundId}", "/api/found-items/cluster/detail",
            "/api/found-items/filter-items", "/api/category"
    };

    private final JwtUtil jwtUtil;
    private final UserService userService;
    private final ObjectMapper objectMapper;

    /**
     * JWT 인증 필터 빈 등록
     *
     * @return JwtAuthenticationFilter 인스턴스
     */
    @Bean
    public JwtAuthenticationFilter jwtAuthenticationFilter() {
        return new JwtAuthenticationFilter(jwtUtil, userService, objectMapper);
    }

    /**
     * Spring Security 필터 체인 구성
     *
     * @param http HttpSecurity 객체
     * @return {@link SecurityFilterChain} 객체
     * @throws Exception 예외 발생 시
     */
    @Bean
    protected SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .cors(cors -> cors
                        .configurationSource(corsConfigurationSource())
                )
                .csrf(CsrfConfigurer::disable)
                .formLogin(AbstractHttpConfigurer::disable)
                .httpBasic(HttpBasicConfigurer::disable)
                .sessionManagement(sessionManagement -> sessionManagement
                        .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                )
                .authorizeHttpRequests(request -> request
                        .requestMatchers(allowUrls).permitAll()
                        .anyRequest().authenticated()
                )
                .addFilterBefore(jwtAuthenticationFilter(), UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    /**
     * CORS 정책을 설정하는 빈을 등록합니다.
     *
     * <p>모든 Origin 및 메서드를 허용하며, 인증 정보(Credentials)는 사용하지 않습니다.
     * 클라이언트가 접근 가능한 헤더 목록도 설정합니다.</p>
     *
     * @return {@link CorsConfigurationSource} 객체
     */
    @Bean
    protected CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();

        // 모든 도메인에서 요청 허용
        configuration.setAllowedOriginPatterns(Collections.singletonList("*"));
        configuration.setAllowedMethods(Collections.singletonList("*"));
        configuration.setAllowCredentials(false);

        // 허용할 요청 헤더
        configuration.setAllowedHeaders(Arrays.asList("Authorization", "Content-Type", "X-Requested-With"));
        configuration.setMaxAge(3600L);

        // 클라이언트에서 접근 가능한 헤더
        configuration.setExposedHeaders(Arrays.asList("Set-Cookie", "Authorization"));

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);

        return source;
    }
}
