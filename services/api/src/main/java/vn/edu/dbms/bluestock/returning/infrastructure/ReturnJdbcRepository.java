package vn.edu.dbms.bluestock.returning.infrastructure;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import vn.edu.dbms.bluestock.returning.application.ReturnModels.CompletionView;
import vn.edu.dbms.bluestock.returning.application.ReturnModels.LineData;
import vn.edu.dbms.bluestock.returning.application.ReturnModels.LineView;
import vn.edu.dbms.bluestock.returning.application.ReturnModels.ReturnPage;
import vn.edu.dbms.bluestock.returning.application.ReturnModels.ReturnSummary;
import vn.edu.dbms.bluestock.returning.application.ReturnModels.ReturnView;

@Repository
public class ReturnJdbcRepository {
    private final JdbcTemplate jdbc;

    public ReturnJdbcRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Optional<String> outboundStatus(String code) {
        return jdbc.queryForList("SELECT TrangThai FROM dbo.PHIEU_XUAT WHERE MaPX = ?",
            String.class, code).stream().findFirst();
    }

    public int nextCodeNumber() {
        Integer number = jdbc.queryForObject("SELECT NEXT VALUE FOR dbo.SEQ_PHIEU_TRA_HANG",
            Integer.class);
        if (number == null) throw new IllegalStateException("Không cấp được mã phiếu trả");
        return number;
    }

    public void insertHeader(String code, String outbound, String employee, String note) {
        jdbc.update("""
            INSERT INTO dbo.PHIEU_TRA_HANG (MaPTH, MaPX, MaNV, GhiChu)
            VALUES (?, ?, ?, ?)
            """, code, outbound, employee, note);
    }

    public void insertLine(String code, LineData line) {
        jdbc.update("""
            INSERT INTO dbo.CT_PHIEU_TRA_HANG (MaPTH, MaLo, MaViTri, SoLuong, TinhTrang)
            VALUES (?, ?, ?, ?, ?)
            """, code, line.maLo(), line.maViTri(), line.soLuong(), line.tinhTrang());
    }

    public Optional<String> lockedStatus(String code) {
        return jdbc.queryForList("""
            SELECT TrangThai FROM dbo.PHIEU_TRA_HANG WITH (UPDLOCK, HOLDLOCK) WHERE MaPTH = ?
            """, String.class, code).stream().findFirst();
    }

    public void updateNote(String code, String note) {
        jdbc.update("UPDATE dbo.PHIEU_TRA_HANG SET GhiChu = ? WHERE MaPTH = ?", note, code);
    }

    public void replaceLines(String code, List<LineData> lines) {
        jdbc.update("DELETE FROM dbo.CT_PHIEU_TRA_HANG WHERE MaPTH = ?", code);
        for (LineData line : lines) insertLine(code, line);
    }

    public void cancel(String code) {
        jdbc.update("UPDATE dbo.PHIEU_TRA_HANG SET TrangThai = N'DA_HUY' WHERE MaPTH = ?", code);
    }

    public ReturnPage findPage(int page, int size, String status, String outbound) {
        String where = "WHERE (? IS NULL OR TrangThai = ?) AND (? IS NULL OR MaPX = ?) ";
        Long count = jdbc.queryForObject(
            "SELECT COUNT_BIG(*) FROM dbo.PHIEU_TRA_HANG " + where,
            Long.class, status, status, outbound, outbound);
        List<ReturnSummary> items = jdbc.query("""
            SELECT MaPTH, NgayTra, MaPX, MaNV, TrangThai, GhiChu, NgayHoanTat
            FROM dbo.PHIEU_TRA_HANG
            """ + where + "ORDER BY NgayTra DESC, MaPTH DESC "
            + "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY", (row, index) ->
                new ReturnSummary(row.getString("MaPTH").trim(),
                    utc(row.getObject("NgayTra", LocalDateTime.class)),
                    row.getString("MaPX").trim(), row.getString("MaNV").trim(),
                    row.getString("TrangThai"), row.getString("GhiChu"),
                    utc(row.getObject("NgayHoanTat", LocalDateTime.class))),
            status, status, outbound, outbound, page * size, size);
        long total = count == null ? 0 : count;
        return new ReturnPage(items, page, size, total, (total + size - 1) / size);
    }

    public Optional<ReturnView> findByCode(String code) {
        List<ReturnView> headers = jdbc.query("""
            SELECT MaPTH, NgayTra, MaPX, MaNV, TrangThai, GhiChu, NgayHoanTat
            FROM dbo.PHIEU_TRA_HANG WHERE MaPTH = ?
            """, (row, index) -> new ReturnView(row.getString("MaPTH").trim(),
                utc(row.getObject("NgayTra", LocalDateTime.class)),
                row.getString("MaPX").trim(), row.getString("MaNV").trim(),
                row.getString("TrangThai"), row.getString("GhiChu"),
                utc(row.getObject("NgayHoanTat", LocalDateTime.class)), List.of()), code);
        if (headers.isEmpty()) return Optional.empty();
        List<LineView> lines = jdbc.query("""
            SELECT line.MaLo, lot.MaSP, product.TenSP,
                   line.MaViTri, line.SoLuong, line.TinhTrang
            FROM dbo.CT_PHIEU_TRA_HANG line
            JOIN dbo.LO_HANG lot ON lot.MaLo = line.MaLo
            JOIN dbo.SAN_PHAM product ON product.MaSP = lot.MaSP
            WHERE line.MaPTH = ? ORDER BY line.MaLo
            """, (row, index) -> new LineView(row.getString("MaLo").trim(),
                row.getString("MaSP").trim(), row.getString("TenSP"),
                row.getString("MaViTri").trim(), row.getInt("SoLuong"),
                row.getString("TinhTrang")), code);
        ReturnView header = headers.getFirst();
        return Optional.of(new ReturnView(header.maPhieuTraHang(), header.ngayTra(),
            header.maPhieuXuat(), header.maNhanVien(), header.trangThai(),
            header.ghiChu(), header.ngayHoanTat(), lines));
    }

    public CompletionView complete(String code, String actorAccount) {
        return jdbc.queryForObject("EXEC dbo.sp_HoanTatTraHang @MaPTH = ?, @MaTK = ?",
            (row, index) -> new CompletionView(row.getString("maPhieuTraHang").trim(),
                row.getString("trangThai"), utc(row.getObject("ngayHoanTat", LocalDateTime.class))),
            code, actorAccount);
    }

    private static OffsetDateTime utc(LocalDateTime value) {
        return value == null ? null : value.atOffset(ZoneOffset.UTC);
    }
}
