package vn.edu.dbms.bluestock.auth.infrastructure;

import java.time.LocalDate;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@ConditionalOnProperty(name = "app.bootstrap-admin.enabled", havingValue = "true")
public class BootstrapAdminRunner implements ApplicationRunner {
    private final JdbcTemplate jdbc;
    private final PasswordEncoder encoder;
    private final String username;
    private final String password;

    public BootstrapAdminRunner(
        JdbcTemplate jdbc,
        PasswordEncoder encoder,
        @Value("${APP_BOOTSTRAP_ADMIN_USERNAME:admin}") String username,
        @Value("${APP_BOOTSTRAP_ADMIN_PASSWORD:}") String password
    ) {
        this.jdbc = jdbc;
        this.encoder = encoder;
        this.username = username;
        this.password = password;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (username.isBlank() || username.length() > 100 || password.length() < 12) {
            throw new IllegalStateException("Bootstrap admin requires a username and password of at least 12 characters");
        }
        Integer count = jdbc.queryForObject(
            "SELECT COUNT(*) FROM dbo.TAI_KHOAN WITH (UPDLOCK, HOLDLOCK)", Integer.class);
        if (count == null || count != 0) {
            throw new IllegalStateException("Bootstrap admin is allowed only when no accounts exist");
        }
        jdbc.update("""
            INSERT INTO dbo.NHAN_VIEN (MaNV, TenNV, NgayVaoLam)
            VALUES (?, ?, ?)
            """, "NV0001", "Quản trị hệ thống", LocalDate.now(ZoneId.of("Asia/Bangkok")));
        jdbc.update("""
            INSERT INTO dbo.TAI_KHOAN (MaTK, MaNV, MaRole, TenTK, MatKhauHash)
            VALUES (?, ?, ?, ?, ?)
            """, "TK0001", "NV0001", "ADMIN", username, encoder.encode(password));
    }
}
