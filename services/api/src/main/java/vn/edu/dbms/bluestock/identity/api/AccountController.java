package vn.edu.dbms.bluestock.identity.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.net.URI;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import vn.edu.dbms.bluestock.auth.infrastructure.AccountPrincipal;
import vn.edu.dbms.bluestock.identity.application.IdentityModels.AccountPage;
import vn.edu.dbms.bluestock.identity.application.IdentityModels.AccountView;
import vn.edu.dbms.bluestock.identity.application.IdentityService;

@RestController
@RequestMapping("/api/tai-khoan")
public class AccountController {
    private final IdentityService service;

    public AccountController(IdentityService service) {
        this.service = service;
    }

    @GetMapping
    public AccountPage list(@RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size) {
        return service.listAccounts(page, size);
    }

    @GetMapping("/{maTaiKhoan}")
    public AccountView get(@PathVariable String maTaiKhoan) {
        return service.getAccount(maTaiKhoan);
    }

    @PostMapping
    public ResponseEntity<AccountView> create(@Valid @RequestBody CreateAccountRequest body,
        @AuthenticationPrincipal AccountPrincipal principal) {
        AccountView created = service.createAccount(body.maTaiKhoan(), body.maNhanVien(),
            body.tenTaiKhoan(), body.role(), body.matKhau(), principal.maTaiKhoan());
        return ResponseEntity.created(URI.create("/api/tai-khoan/" + created.maTaiKhoan()))
            .body(created);
    }

    @PutMapping("/{maTaiKhoan}")
    public AccountView update(@PathVariable String maTaiKhoan,
        @Valid @RequestBody UpdateAccountRequest body,
        @AuthenticationPrincipal AccountPrincipal principal) {
        return service.updateAccount(maTaiKhoan, body.tenTaiKhoan(), body.role(),
            body.trangThai(), principal.maTaiKhoan());
    }

    @PutMapping("/{maTaiKhoan}/mat-khau")
    public ResponseEntity<Void> resetPassword(@PathVariable String maTaiKhoan,
        @Valid @RequestBody ResetPasswordRequest body,
        @AuthenticationPrincipal AccountPrincipal principal) {
        service.resetPassword(maTaiKhoan, body.matKhauMoi(), principal.maTaiKhoan());
        return ResponseEntity.noContent().build();
    }

    public record CreateAccountRequest(String maTaiKhoan,
        @NotBlank String maNhanVien,
        @NotBlank @Size(max = 100) String tenTaiKhoan,
        @NotBlank String role,
        @NotBlank @Size(min = 12, max = 72) String matKhau) {}

    public record UpdateAccountRequest(@NotBlank @Size(max = 100) String tenTaiKhoan,
        @NotBlank String role, @NotNull Boolean trangThai) {}

    public record ResetPasswordRequest(@NotBlank @Size(min = 12, max = 72)
        String matKhauMoi) {}
}
