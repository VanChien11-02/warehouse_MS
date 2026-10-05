package vn.edu.dbms.bluestock.auth.infrastructure;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class JdbcAccountDetailsService implements UserDetailsService {
    private final JdbcTemplate jdbc;

    public JdbcAccountDetailsService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        var accounts = jdbc.query("""
            SELECT tk.MaTK, tk.MaNV, nv.TenNV, tk.TenTK, tk.MatKhauHash,
                   tk.MaRole, tk.TrangThai, nv.DangLamViec
            FROM dbo.TAI_KHOAN tk
            JOIN dbo.NHAN_VIEN nv ON nv.MaNV = tk.MaNV
            WHERE tk.TenTK = ?
            """, (row, index) -> new AccountPrincipal(
                row.getString("MaTK").trim(),
                row.getString("MaNV").trim(),
                row.getString("TenNV"),
                row.getString("TenTK"),
                row.getString("MatKhauHash"),
                row.getString("MaRole").trim(),
                row.getBoolean("TrangThai") && row.getBoolean("DangLamViec")
            ), username);
        if (accounts.isEmpty()) {
            throw new UsernameNotFoundException("Account unavailable");
        }
        return accounts.getFirst();
    }
}
