package vn.edu.dbms.bluestock.identity.infrastructure;

import java.sql.Date;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import vn.edu.dbms.bluestock.identity.application.IdentityModels.AccountPage;
import vn.edu.dbms.bluestock.identity.application.IdentityModels.AccountView;
import vn.edu.dbms.bluestock.identity.application.IdentityModels.EmployeeData;
import vn.edu.dbms.bluestock.identity.application.IdentityModels.EmployeePage;
import vn.edu.dbms.bluestock.identity.application.IdentityModels.EmployeeView;

@Repository
public class IdentityJdbcRepository {
    private final JdbcTemplate jdbc;

    public IdentityJdbcRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public EmployeePage employeePage(int page, int size) {
        Long count = jdbc.queryForObject("SELECT COUNT_BIG(*) FROM dbo.NHAN_VIEN", Long.class);
        List<EmployeeView> items = jdbc.query("""
            SELECT MaNV, TenNV, SDT, GioiTinh, NgaySinh, DiaChi, Luong,
                   NgayVaoLam, DangLamViec
            FROM dbo.NHAN_VIEN ORDER BY MaNV
            OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
            """, (row, index) -> employee(row), page * size, size);
        long total = count == null ? 0 : count;
        return new EmployeePage(items, page, size, total, (total + size - 1) / size);
    }

    public Optional<EmployeeView> employee(String code) {
        return jdbc.query("""
            SELECT MaNV, TenNV, SDT, GioiTinh, NgaySinh, DiaChi, Luong,
                   NgayVaoLam, DangLamViec
            FROM dbo.NHAN_VIEN WHERE MaNV = ?
            """, (row, index) -> employee(row), code).stream().findFirst();
    }

    public Optional<Boolean> lockedEmployeeActive(String code) {
        return jdbc.queryForList("""
            SELECT DangLamViec FROM dbo.NHAN_VIEN WITH (UPDLOCK, HOLDLOCK) WHERE MaNV = ?
            """, Boolean.class, code).stream().findFirst();
    }

    public void insertEmployee(String code, EmployeeData data) {
        jdbc.update("""
            INSERT INTO dbo.NHAN_VIEN
                (MaNV, TenNV, SDT, GioiTinh, NgaySinh, DiaChi, Luong, NgayVaoLam, DangLamViec)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, code, data.tenNhanVien(), data.soDienThoai(), data.gioiTinh(),
            data.ngaySinh(), data.diaChi(), data.luong(), data.ngayVaoLam(), data.dangLamViec());
    }

    public void updateEmployee(String code, EmployeeData data) {
        jdbc.update("""
            UPDATE dbo.NHAN_VIEN
            SET TenNV = ?, SDT = ?, GioiTinh = ?, NgaySinh = ?, DiaChi = ?,
                Luong = ?, NgayVaoLam = ?, DangLamViec = ?
            WHERE MaNV = ?
            """, data.tenNhanVien(), data.soDienThoai(), data.gioiTinh(),
            data.ngaySinh(), data.diaChi(), data.luong(), data.ngayVaoLam(),
            data.dangLamViec(), code);
    }

    public AccountPage accountPage(int page, int size) {
        Long count = jdbc.queryForObject("SELECT COUNT_BIG(*) FROM dbo.TAI_KHOAN", Long.class);
        List<AccountView> items = jdbc.query("""
            SELECT tk.MaTK, tk.MaNV, nv.TenNV, tk.TenTK, tk.MaRole, tk.TrangThai
            FROM dbo.TAI_KHOAN tk JOIN dbo.NHAN_VIEN nv ON nv.MaNV = tk.MaNV
            ORDER BY tk.MaTK OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
            """, (row, index) -> account(row), page * size, size);
        long total = count == null ? 0 : count;
        return new AccountPage(items, page, size, total, (total + size - 1) / size);
    }

    public Optional<AccountView> account(String code) {
        return jdbc.query("""
            SELECT tk.MaTK, tk.MaNV, nv.TenNV, tk.TenTK, tk.MaRole, tk.TrangThai
            FROM dbo.TAI_KHOAN tk JOIN dbo.NHAN_VIEN nv ON nv.MaNV = tk.MaNV
            WHERE tk.MaTK = ?
            """, (row, index) -> account(row), code).stream().findFirst();
    }

    public Optional<AccountView> lockedAccount(String code) {
        return jdbc.query("""
            SELECT tk.MaTK, tk.MaNV, nv.TenNV, tk.TenTK, tk.MaRole, tk.TrangThai
            FROM dbo.TAI_KHOAN tk WITH (UPDLOCK, HOLDLOCK)
            JOIN dbo.NHAN_VIEN nv ON nv.MaNV = tk.MaNV
            WHERE tk.MaTK = ?
            """, (row, index) -> account(row), code).stream().findFirst();
    }

    public void insertAccount(String code, String employee, String username,
        String role, String hash) {
        jdbc.update("""
            INSERT INTO dbo.TAI_KHOAN (MaTK, MaNV, TenTK, MaRole, MatKhauHash)
            VALUES (?, ?, ?, ?, ?)
            """, code, employee, username, role, hash);
    }

    public void updateAccount(String code, String username, String role, boolean active) {
        jdbc.update("""
            UPDATE dbo.TAI_KHOAN SET TenTK = ?, MaRole = ?, TrangThai = ? WHERE MaTK = ?
            """, username, role, active, code);
    }

    public void resetPassword(String code, String hash) {
        jdbc.update("UPDATE dbo.TAI_KHOAN SET MatKhauHash = ? WHERE MaTK = ?", hash, code);
    }

    private static EmployeeView employee(java.sql.ResultSet row) throws java.sql.SQLException {
        Date birthday = row.getDate("NgaySinh");
        LocalDate joined = row.getDate("NgayVaoLam").toLocalDate();
        return new EmployeeView(row.getString("MaNV").trim(), row.getString("TenNV"),
            row.getString("SDT"), row.getString("GioiTinh"),
            birthday == null ? null : birthday.toLocalDate(), row.getString("DiaChi"),
            row.getBigDecimal("Luong"), joined, row.getBoolean("DangLamViec"));
    }

    private static AccountView account(java.sql.ResultSet row) throws java.sql.SQLException {
        return new AccountView(row.getString("MaTK").trim(), row.getString("MaNV").trim(),
            row.getString("TenNV"), row.getString("TenTK"),
            row.getString("MaRole").trim(), row.getBoolean("TrangThai"));
    }
}
