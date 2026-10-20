package vn.edu.dbms.bluestock.auth.api;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.Map;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.logout.SecurityContextLogoutHandler;
import org.springframework.security.web.context.SecurityContextRepository;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import vn.edu.dbms.bluestock.auth.application.AuthApplicationService;
import vn.edu.dbms.bluestock.auth.application.PasswordChangeService;
import vn.edu.dbms.bluestock.auth.infrastructure.AccountPrincipal;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final AuthApplicationService authService;
    private final SecurityContextRepository contextRepository;
    private final PasswordChangeService passwordChangeService;

    public AuthController(AuthApplicationService authService, SecurityContextRepository contextRepository,
        PasswordChangeService passwordChangeService) {
        this.authService = authService;
        this.contextRepository = contextRepository;
        this.passwordChangeService = passwordChangeService;
    }

    @GetMapping("/csrf")
    public Map<String, String> csrf(CsrfToken token) {
        return Map.of("token", token.getToken(), "headerName", token.getHeaderName());
    }

    @PostMapping("/dang-nhap")
    public AuthUserResponse login(
        @Valid @RequestBody LoginRequest body,
        HttpServletRequest request,
        HttpServletResponse response
    ) {
        Authentication authentication = authService.authenticate(body.tenTaiKhoan(), body.matKhau());
        request.changeSessionId();
        var context = SecurityContextHolder.createEmptyContext();
        context.setAuthentication(authentication);
        SecurityContextHolder.setContext(context);
        contextRepository.saveContext(context, request, response);
        return AuthUserResponse.from((AccountPrincipal) authentication.getPrincipal());
    }

    @GetMapping("/me")
    public AuthUserResponse me(@AuthenticationPrincipal AccountPrincipal principal) {
        return AuthUserResponse.from(principal);
    }

    @PostMapping("/dang-xuat")
    public ResponseEntity<Void> logout(
        Authentication authentication,
        HttpServletRequest request,
        HttpServletResponse response
    ) {
        new SecurityContextLogoutHandler().logout(request, response, authentication);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/doi-mat-khau")
    public ResponseEntity<Void> changePassword(@Valid @RequestBody ChangePasswordRequest body,
        @AuthenticationPrincipal AccountPrincipal principal) {
        passwordChangeService.change(principal.maTaiKhoan(), body.matKhauCu(), body.matKhauMoi());
        return ResponseEntity.noContent().build();
    }

    public record LoginRequest(@NotBlank String tenTaiKhoan, @NotBlank String matKhau) {}

    public record ChangePasswordRequest(@NotBlank String matKhauCu,
        @NotBlank @Size(min = 12, max = 72) String matKhauMoi) {}

    public record AuthUserResponse(
        String maTaiKhoan,
        String maNhanVien,
        String tenNhanVien,
        String tenTaiKhoan,
        String role
    ) {
        static AuthUserResponse from(AccountPrincipal principal) {
            return new AuthUserResponse(
                principal.maTaiKhoan(),
                principal.maNhanVien(),
                principal.tenNhanVien(),
                principal.username(),
                principal.roleCode());
        }
    }
}
