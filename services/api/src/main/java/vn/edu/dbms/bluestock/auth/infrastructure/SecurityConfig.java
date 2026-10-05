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
                .requestMatchers(HttpMethod.GET, "/api/san-pham", "/api/san-pham/*")
                    .authenticated()
                .requestMatchers(HttpMethod.POST, "/api/san-pham")
                    .hasAnyAuthority("ROLE_ADMIN", "ROLE_QLKHO")
                .requestMatchers(HttpMethod.PUT, "/api/san-pham/*")
                    .hasAnyAuthority("ROLE_ADMIN", "ROLE_QLKHO")
                .requestMatchers(HttpMethod.DELETE, "/api/san-pham/*")
                    .hasAnyAuthority("ROLE_ADMIN", "ROLE_QLKHO")
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
