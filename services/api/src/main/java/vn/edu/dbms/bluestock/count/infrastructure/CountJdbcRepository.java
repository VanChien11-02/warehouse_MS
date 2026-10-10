package vn.edu.dbms.bluestock.count.infrastructure;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import vn.edu.dbms.bluestock.count.application.CountModels.CompletionView;
import vn.edu.dbms.bluestock.count.application.CountModels.CountPage;
import vn.edu.dbms.bluestock.count.application.CountModels.CountSummary;
import vn.edu.dbms.bluestock.count.application.CountModels.CountView;
import vn.edu.dbms.bluestock.count.application.CountModels.LineView;

@Repository
public class CountJdbcRepository {
    private final JdbcTemplate jdbc;

    public CountJdbcRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public record Stock(String maLo, int soLuong) {}

    public boolean lockPosition(String position) {
        return !jdbc.queryForList("""
            SELECT MaViTri FROM dbo.VI_TRI_KHO WITH (UPDLOCK, HOLDLOCK) WHERE MaViTri = ?
            """, String.class, position).isEmpty();
    }

    public List<Stock> lockPositiveStock(String position) {
        return jdbc.query("""
            SELECT MaLo, SoLuongTon FROM dbo.TON_KHO WITH (UPDLOCK, HOLDLOCK)
            WHERE MaViTri = ? AND SoLuongTon > 0 ORDER BY MaLo
            """, (row, index) -> new Stock(row.getString("MaLo").trim(),
                row.getInt("SoLuongTon")), position);
    }

    public int nextCodeNumber() {
        Integer number = jdbc.queryForObject("SELECT NEXT VALUE FOR dbo.SEQ_PHIEU_KIEM_KE",
            Integer.class);
        if (number == null) throw new IllegalStateException("Không cấp được mã phiếu kiểm kê");
        return number;
    }

    public void insertHeader(String code, String employee, String position, String note) {
        jdbc.update("""
            INSERT INTO dbo.PHIEU_KIEM_KE (MaPKK, MaNV, MaViTri, GhiChu)
            VALUES (?, ?, ?, ?)
            """, code, employee, position, note);
    }

    public void insertSnapshotLine(String code, String lot, int systemQuantity) {
        jdbc.update("""
            INSERT INTO dbo.CT_KIEM_KE (MaPKK, MaLo, SoLuongHeThong)
            VALUES (?, ?, ?)
            """, code, lot, systemQuantity);
    }

    public Optional<String> lockedStatus(String code) {
        return jdbc.queryForList("""
            SELECT TrangThai FROM dbo.PHIEU_KIEM_KE WITH (UPDLOCK, HOLDLOCK) WHERE MaPKK = ?
            """, String.class, code).stream().findFirst();
    }

    public String lockPositionForCount(String code) {
        String position = jdbc.queryForObject(
            "SELECT MaViTri FROM dbo.PHIEU_KIEM_KE WHERE MaPKK = ?", String.class, code);
        lockPosition(position);
        return position.trim();
    }

    public boolean hasLine(String code, String lot) {
        return !jdbc.queryForList("""
            SELECT MaLo FROM dbo.CT_KIEM_KE WHERE MaPKK = ? AND MaLo = ?
            """, String.class, code, lot).isEmpty();
    }

    public int lockStockQuantity(String position, String lot) {
        Integer quantity = jdbc.queryForObject("""
            SELECT COALESCE((SELECT SoLuongTon FROM dbo.TON_KHO WITH (UPDLOCK, HOLDLOCK)
                WHERE MaViTri = ? AND MaLo = ?), 0)
            """, Integer.class, position, lot);
        return quantity == null ? 0 : quantity;
    }

    public void updateActual(String code, String lot, int actual, String reason) {
        jdbc.update("""
            UPDATE dbo.CT_KIEM_KE SET SoLuongThucTe = ?, LyDoChenhLech = ?
            WHERE MaPKK = ? AND MaLo = ?
            """, actual, reason, code, lot);
    }

    public void insertActualLine(String code, String lot, int actual, String reason) {
        jdbc.update("""
            INSERT INTO dbo.CT_KIEM_KE
                (MaPKK, MaLo, SoLuongHeThong, SoLuongThucTe, LyDoChenhLech)
            VALUES (?, ?, 0, ?, ?)
            """, code, lot, actual, reason);
    }

    public int cancel(String code) {
        return jdbc.update("UPDATE dbo.PHIEU_KIEM_KE SET TrangThai = N'DA_HUY' "
            + "WHERE MaPKK = ? AND TrangThai = N'NHAP'", code);
    }

    public CountPage findPage(int page, int size, String status, String position) {
        String where = "WHERE (? IS NULL OR TrangThai = ?) AND (? IS NULL OR MaViTri = ?) ";
        Long count = jdbc.queryForObject(
            "SELECT COUNT_BIG(*) FROM dbo.PHIEU_KIEM_KE " + where,
            Long.class, status, status, position, position);
        List<CountSummary> items = jdbc.query("""
            SELECT MaPKK, NgayKiemKe, MaNV, MaViTri, TrangThai, GhiChu, NgayHoanTat
            FROM dbo.PHIEU_KIEM_KE
            """ + where + "ORDER BY NgayKiemKe DESC, MaPKK DESC "
            + "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY", (row, index) ->
                new CountSummary(row.getString("MaPKK").trim(),
                    utc(row.getObject("NgayKiemKe", LocalDateTime.class)),
                    row.getString("MaNV").trim(), row.getString("MaViTri").trim(),
                    row.getString("TrangThai"), row.getString("GhiChu"),
                    utc(row.getObject("NgayHoanTat", LocalDateTime.class))),
            status, status, position, position, page * size, size);
        long total = count == null ? 0 : count;
        return new CountPage(items, page, size, total, (total + size - 1) / size);
    }

    public Optional<CountView> findByCode(String code) {
        List<CountView> headers = jdbc.query("""
            SELECT MaPKK, NgayKiemKe, MaNV, MaViTri, TrangThai, GhiChu, NgayHoanTat
            FROM dbo.PHIEU_KIEM_KE WHERE MaPKK = ?
            """, (row, index) -> new CountView(row.getString("MaPKK").trim(),
                utc(row.getObject("NgayKiemKe", LocalDateTime.class)),
                row.getString("MaNV").trim(), row.getString("MaViTri").trim(),
                row.getString("TrangThai"), row.getString("GhiChu"),
                utc(row.getObject("NgayHoanTat", LocalDateTime.class)), List.of()), code);
        if (headers.isEmpty()) return Optional.empty();
        List<LineView> lines = jdbc.query("""
            SELECT ct.MaLo, lot.MaSP, product.TenSP, ct.SoLuongHeThong,
                   ct.SoLuongThucTe, ct.LyDoChenhLech
            FROM dbo.CT_KIEM_KE ct
            JOIN dbo.LO_HANG lot ON lot.MaLo = ct.MaLo
            JOIN dbo.SAN_PHAM product ON product.MaSP = lot.MaSP
            WHERE ct.MaPKK = ? ORDER BY ct.MaLo
            """, (row, index) -> new LineView(row.getString("MaLo").trim(),
                row.getString("MaSP").trim(), row.getString("TenSP"),
                row.getInt("SoLuongHeThong"), row.getObject("SoLuongThucTe", Integer.class),
                row.getString("LyDoChenhLech")), code);
        CountView header = headers.getFirst();
        return Optional.of(new CountView(header.maPhieuKiemKe(), header.ngayKiemKe(),
            header.maNhanVien(), header.maViTri(), header.trangThai(),
            header.ghiChu(), header.ngayHoanTat(), lines));
    }

    public CompletionView complete(String code, String actorAccount) {
        return jdbc.queryForObject("EXEC dbo.sp_HoanTatKiemKe @MaPKK = ?, @MaTK = ?",
            (row, index) -> new CompletionView(row.getString("maPhieuKiemKe").trim(),
                row.getString("trangThai"), utc(row.getObject("ngayHoanTat", LocalDateTime.class))),
            code, actorAccount);
    }

    private static OffsetDateTime utc(LocalDateTime value) {
        return value == null ? null : value.atOffset(ZoneOffset.UTC);
    }
}
