package vn.edu.dbms.bluestock.transfer.infrastructure;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import vn.edu.dbms.bluestock.transfer.application.TransferModels.CompletionView;
import vn.edu.dbms.bluestock.transfer.application.TransferModels.LineData;
import vn.edu.dbms.bluestock.transfer.application.TransferModels.LineView;
import vn.edu.dbms.bluestock.transfer.application.TransferModels.TransferView;
import vn.edu.dbms.bluestock.transfer.application.TransferModels.TransferSummary;
import vn.edu.dbms.bluestock.transfer.application.TransferModels.TransferPage;

@Repository
public class TransferJdbcRepository {
    private final JdbcTemplate jdbc;

    public TransferJdbcRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public int nextCodeNumber() {
        Integer number = jdbc.queryForObject("SELECT NEXT VALUE FOR dbo.SEQ_PHIEU_CHUYEN_KHO",
            Integer.class);
        if (number == null) throw new IllegalStateException("Không cấp được mã phiếu chuyển");
        return number;
    }

    public void insertHeader(String code, String employee, String note) {
        jdbc.update("INSERT INTO dbo.PHIEU_CHUYEN_KHO (MaPCK, MaNV, GhiChu) VALUES (?, ?, ?)",
            code, employee, note);
    }

    public void insertLine(String code, LineData line) {
        jdbc.update("""
            INSERT INTO dbo.CT_PHIEU_CHUYEN_KHO
                (MaPCK, MaLo, MaViTriNguon, MaViTriDich, SoLuong)
            VALUES (?, ?, ?, ?, ?)
            """, code, line.maLo(), line.maViTriNguon(), line.maViTriDich(), line.soLuong());
    }

    public TransferPage findPage(int page, int size, String status) {
        String where = status == null ? "" : "WHERE TrangThai = ? ";
        Object[] countArgs = status == null ? new Object[] {} : new Object[] {status};
        Long count = jdbc.queryForObject("SELECT COUNT_BIG(*) FROM dbo.PHIEU_CHUYEN_KHO " + where,
            Long.class, countArgs);
        Object[] pageArgs = status == null
            ? new Object[] {page * size, size}
            : new Object[] {status, page * size, size};
        List<TransferSummary> items = jdbc.query("""
            SELECT MaPCK, NgayChuyen, MaNV, TrangThai, GhiChu, NgayHoanTat
            FROM dbo.PHIEU_CHUYEN_KHO
            """ + where + "ORDER BY NgayChuyen DESC, MaPCK DESC "
            + "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY", (row, index) ->
                new TransferSummary(row.getString("MaPCK").trim(),
                    utc(row.getObject("NgayChuyen", LocalDateTime.class)),
                    row.getString("MaNV").trim(), row.getString("TrangThai"),
                    row.getString("GhiChu"), utc(row.getObject("NgayHoanTat", LocalDateTime.class))),
            pageArgs);
        long total = count == null ? 0 : count;
        return new TransferPage(items, page, size, total, (total + size - 1) / size);
    }

    public Optional<String> lockedStatus(String code) {
        return jdbc.queryForList("""
            SELECT TrangThai FROM dbo.PHIEU_CHUYEN_KHO WITH (UPDLOCK, HOLDLOCK) WHERE MaPCK = ?
            """, String.class, code).stream().findFirst();
    }

    public void updateNote(String code, String note) {
        jdbc.update("UPDATE dbo.PHIEU_CHUYEN_KHO SET GhiChu = ? WHERE MaPCK = ?", note, code);
    }

    public void replaceLines(String code, List<LineData> lines) {
        jdbc.update("DELETE FROM dbo.CT_PHIEU_CHUYEN_KHO WHERE MaPCK = ?", code);
        for (LineData line : lines) insertLine(code, line);
    }

    public int cancel(String code) {
        return jdbc.update("UPDATE dbo.PHIEU_CHUYEN_KHO SET TrangThai = N'DA_HUY' "
            + "WHERE MaPCK = ? AND TrangThai = N'NHAP'", code);
    }

    public Optional<TransferView> findByCode(String code) {
        List<TransferView> headers = jdbc.query("""
            SELECT MaPCK, NgayChuyen, MaNV, TrangThai, GhiChu, NgayHoanTat
            FROM dbo.PHIEU_CHUYEN_KHO WHERE MaPCK = ?
            """, (row, index) -> new TransferView(row.getString("MaPCK").trim(),
                utc(row.getObject("NgayChuyen", LocalDateTime.class)),
                row.getString("MaNV").trim(), row.getString("TrangThai"),
                row.getString("GhiChu"), utc(row.getObject("NgayHoanTat", LocalDateTime.class)),
                List.of()), code);
        if (headers.isEmpty()) return Optional.empty();
        List<LineView> lines = jdbc.query("""
            SELECT ct.MaLo, lo.MaSP, sp.TenSP, ct.MaViTriNguon,
                   ct.MaViTriDich, ct.SoLuong
            FROM dbo.CT_PHIEU_CHUYEN_KHO ct
            JOIN dbo.LO_HANG lo ON lo.MaLo = ct.MaLo
            JOIN dbo.SAN_PHAM sp ON sp.MaSP = lo.MaSP
            WHERE ct.MaPCK = ? ORDER BY ct.MaLo, ct.MaViTriNguon, ct.MaViTriDich
            """, (row, index) -> new LineView(row.getString("MaLo").trim(),
                row.getString("MaSP").trim(), row.getString("TenSP"),
                row.getString("MaViTriNguon").trim(),
                row.getString("MaViTriDich").trim(), row.getInt("SoLuong")), code);
        TransferView header = headers.getFirst();
        return Optional.of(new TransferView(header.maPhieuChuyen(), header.ngayChuyen(),
            header.maNhanVien(), header.trangThai(), header.ghiChu(),
            header.ngayHoanTat(), lines));
    }

    public CompletionView complete(String code, String actorAccount) {
        return jdbc.queryForObject("EXEC dbo.sp_HoanTatChuyenKho @MaPCK = ?, @MaTK = ?",
            (row, index) -> new CompletionView(row.getString("maPhieuChuyen").trim(),
                row.getString("trangThai"), utc(row.getObject("ngayHoanTat", LocalDateTime.class))),
            code, actorAccount);
    }

    private static OffsetDateTime utc(LocalDateTime value) {
        return value == null ? null : value.atOffset(ZoneOffset.UTC);
    }
}
