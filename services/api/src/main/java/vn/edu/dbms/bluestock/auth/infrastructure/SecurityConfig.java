package vn.edu.dbms.bluestock.auth.infrastructure;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletResponse;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.ProviderManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.security.web.context.SecurityContextRepository;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import vn.edu.dbms.bluestock.platform.api.ApiError;

@Configuration
public class SecurityConfig {
    @Bean
    SecurityFilterChain securityFilterChain(
        HttpSecurity http,
        SecurityContextRepository contextRepository,
        ObjectMapper objectMapper
    )
        throws Exception {
        return http
            .cors(Customizer.withDefaults())
            .csrf(Customizer.withDefaults())
            .securityContext(context -> context.securityContextRepository(contextRepository))
            .authorizeHttpRequests(authorize -> authorize
                .requestMatchers(HttpMethod.GET, "/api/health", "/actuator/health", "/api/auth/csrf")
                    .permitAll()
                .requestMatchers(HttpMethod.POST, "/api/auth/dang-nhap").permitAll()
                .requestMatchers("/api/auth/**").authenticated()
                .requestMatchers("/api/nhan-vien", "/api/nhan-vien/*",
                    "/api/tai-khoan", "/api/tai-khoan/*", "/api/tai-khoan/*/mat-khau")
                    .hasAuthority("ROLE_ADMIN")
                .requestMatchers(HttpMethod.GET, "/api/audit").denyAll()
                .requestMatchers(HttpMethod.GET, "/api/quyen-han").hasAuthority("ROLE_ADMIN")
                .requestMatchers(HttpMethod.GET, "/api/doi-soat-gia-tri/*/*")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_KETOAN")
                .requestMatchers(HttpMethod.POST, "/api/doi-soat-gia-tri/*/*")
                    .hasAuthority("ROLE_KETOAN")
                .requestMatchers(HttpMethod.GET, "/api/san-pham", "/api/san-pham/*")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_NVKHO", "ROLE_KETOAN")
                .requestMatchers(HttpMethod.POST, "/api/san-pham")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.PUT, "/api/san-pham/*")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.DELETE, "/api/san-pham/*")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.GET, "/api/loai-san-pham", "/api/loai-san-pham/*",
                    "/api/don-vi-tinh", "/api/don-vi-tinh/*")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_NVKHO", "ROLE_KETOAN")
                .requestMatchers(HttpMethod.POST, "/api/loai-san-pham", "/api/don-vi-tinh")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.PUT, "/api/loai-san-pham/*", "/api/don-vi-tinh/*")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.DELETE, "/api/loai-san-pham/*", "/api/don-vi-tinh/*")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.GET, "/api/kho", "/api/kho/*",
                    "/api/khu-vuc", "/api/khu-vuc/*")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_NVKHO", "ROLE_KETOAN")
                .requestMatchers(HttpMethod.POST, "/api/kho", "/api/khu-vuc")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.PUT, "/api/kho/*", "/api/khu-vuc/*")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.DELETE, "/api/kho/*", "/api/khu-vuc/*")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.GET, "/api/vi-tri", "/api/vi-tri/*")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_NVKHO", "ROLE_KETOAN")
                .requestMatchers(HttpMethod.POST, "/api/vi-tri")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.PUT, "/api/vi-tri/*")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.DELETE, "/api/vi-tri/*")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.GET, "/api/nha-cung-cap", "/api/nha-cung-cap/*",
                    "/api/nha-cung-cap/*/san-pham")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_NVKHO", "ROLE_KETOAN")
                .requestMatchers(HttpMethod.POST, "/api/nha-cung-cap",
                    "/api/nha-cung-cap/*/san-pham/*").hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.PUT, "/api/nha-cung-cap/*")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.DELETE, "/api/nha-cung-cap/*",
                    "/api/nha-cung-cap/*/san-pham/*").hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.GET, "/api/doi-tac-nhan-hang", "/api/doi-tac-nhan-hang/*",
                    "/api/doi-tac-nhan-hang/*/san-pham")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_NVKHO", "ROLE_KETOAN")
                .requestMatchers(HttpMethod.POST, "/api/doi-tac-nhan-hang",
                    "/api/doi-tac-nhan-hang/*/san-pham/*")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.PUT, "/api/doi-tac-nhan-hang/*")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.DELETE, "/api/doi-tac-nhan-hang/*",
                    "/api/doi-tac-nhan-hang/*/san-pham/*")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.GET, "/api/phieu-nhap/lich-su")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_KETOAN")
                .requestMatchers(HttpMethod.GET, "/api/phieu-nhap", "/api/phieu-nhap/*")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_NVKHO", "ROLE_KETOAN")
                .requestMatchers(HttpMethod.POST, "/api/phieu-nhap")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_NVKHO")
                .requestMatchers(HttpMethod.PUT, "/api/phieu-nhap/*")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_NVKHO")
                .requestMatchers(HttpMethod.POST, "/api/phieu-nhap/*/huy")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_NVKHO")
                .requestMatchers(HttpMethod.POST, "/api/phieu-nhap/*/hoan-tat")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.GET, "/api/ton-kho", "/api/ton-kho/theo-san-pham")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_NVKHO", "ROLE_KETOAN")
                .requestMatchers(HttpMethod.GET, "/api/phieu-xuat", "/api/phieu-xuat/*")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_NVKHO", "ROLE_KETOAN")
                .requestMatchers(HttpMethod.GET, "/api/phieu-xuat/*/goi-y-fefo")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_NVKHO")
                .requestMatchers(HttpMethod.POST, "/api/phieu-xuat")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_NVKHO")
                .requestMatchers(HttpMethod.PUT, "/api/phieu-xuat/*")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_NVKHO")
                .requestMatchers(HttpMethod.POST, "/api/phieu-xuat/*/huy")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_NVKHO")
                .requestMatchers(HttpMethod.POST, "/api/phieu-xuat/*/hoan-tat")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.GET, "/api/bao-cao/nhap-xuat")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_KETOAN")
                .requestMatchers(HttpMethod.GET, "/api/bao-cao/chenh-lech-kiem-ke")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_KETOAN")
                .requestMatchers(HttpMethod.GET, "/api/bao-cao/lo-sap-het-han")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.GET, "/api/phieu-chuyen", "/api/phieu-chuyen/*")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_KETOAN")
                .requestMatchers(HttpMethod.POST, "/api/phieu-chuyen")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.PUT, "/api/phieu-chuyen/*")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.POST, "/api/phieu-chuyen/*/huy")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.POST, "/api/phieu-chuyen/*/hoan-tat")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.GET, "/api/phieu-kiem-ke", "/api/phieu-kiem-ke/*")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_KETOAN")
                .requestMatchers(HttpMethod.POST, "/api/phieu-kiem-ke")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.PUT, "/api/phieu-kiem-ke/*/chi-tiet/*")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.POST, "/api/phieu-kiem-ke/*/huy")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.POST, "/api/phieu-kiem-ke/*/hoan-tat")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.GET, "/api/phieu-tra-hang", "/api/phieu-tra-hang/*")
                    .hasAnyAuthority("ROLE_QLKHO", "ROLE_KETOAN")
                .requestMatchers(HttpMethod.POST, "/api/phieu-tra-hang")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.PUT, "/api/phieu-tra-hang/*")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.POST, "/api/phieu-tra-hang/*/huy")
                    .hasAuthority("ROLE_QLKHO")
                .requestMatchers(HttpMethod.POST, "/api/phieu-tra-hang/*/hoan-tat")
                    .hasAuthority("ROLE_QLKHO")
                .anyRequest().denyAll())
            .exceptionHandling(errors -> errors
                .authenticationEntryPoint((request, response, exception) ->
                    writeError(response, objectMapper, HttpServletResponse.SC_UNAUTHORIZED,
                        "UNAUTHORIZED", "Cần đăng nhập"))
                .accessDeniedHandler((request, response, exception) ->
                    writeError(response, objectMapper, HttpServletResponse.SC_FORBIDDEN,
                        "FORBIDDEN", "Không có quyền truy cập")))
            .httpBasic(AbstractHttpConfigurer::disable)
            .formLogin(AbstractHttpConfigurer::disable)
            .build();
    }

    @Bean
    SecurityContextRepository securityContextRepository() {
        return new HttpSessionSecurityContextRepository();
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    AuthenticationManager authenticationManager(UserDetailsService userDetailsService, PasswordEncoder encoder) {
        var provider = new DaoAuthenticationProvider(userDetailsService);
        provider.setPasswordEncoder(encoder);
        return new ProviderManager(provider);
    }

    @Bean
    CorsConfigurationSource corsConfigurationSource(
        @Value("${app.web-origin:http://127.0.0.1:5174}") String webOrigin
    ) {
        var configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(List.of(webOrigin));
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("Content-Type", "X-CSRF-TOKEN"));
        configuration.setAllowCredentials(true);
        var source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", configuration);
        return source;
    }

    private static void writeError(
        HttpServletResponse response,
        ObjectMapper objectMapper,
        int status,
        String code,
        String message
    ) throws java.io.IOException {
        response.setStatus(status);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        objectMapper.writeValue(response.getOutputStream(), ApiError.of(code, message));
    }
}
