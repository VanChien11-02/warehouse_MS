package vn.edu.dbms.bluestock.auth.application;

import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.edu.dbms.bluestock.audit.application.AuditTrail;

@Service
public class PasswordChangeService {
    private final JdbcTemplate jdbc;
    private final PasswordEncoder encoder;
    private final AuditTrail audit;

    public PasswordChangeService(JdbcTemplate jdbc, PasswordEncoder encoder, AuditTrail audit) {
        this.jdbc = jdbc;
        this.encoder = encoder;
        this.audit = audit;
    }

    @Transactional
    public void change(String accountCode, String oldPassword, String newPassword) {
        List<String> hashes = jdbc.queryForList("""
            SELECT tk.MatKhauHash FROM dbo.TAI_KHOAN tk WITH (UPDLOCK, HOLDLOCK)
            JOIN dbo.NHAN_VIEN nv ON nv.MaNV = tk.MaNV
            WHERE tk.MaTK = ? AND tk.TrangThai = 1 AND nv.DangLamViec = 1
            """, String.class, accountCode);
        if (hashes.isEmpty() || !encoder.matches(oldPassword, hashes.getFirst())) {
            throw new BadCredentialsException("Invalid credentials");
        }
        if (encoder.matches(newPassword, hashes.getFirst())) {
            throw new PasswordChangeException();
        }
        jdbc.update("UPDATE dbo.TAI_KHOAN SET MatKhauHash = ? WHERE MaTK = ?",
            encoder.encode(newPassword), accountCode);
        audit.record(accountCode, "PASSWORD_CHANGE", "TAI_KHOAN", accountCode, null, null);
    }
}
