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

    public CompletionView complete(String code) {
        return jdbc.queryForObject("EXEC dbo.sp_HoanTatChuyenKho @MaPCK = ?",
            (row, index) -> new CompletionView(row.getString("maPhieuChuyen").trim(),
                row.getString("trangThai"), utc(row.getObject("ngayHoanTat", LocalDateTime.class))),
            code);
    }

    private static OffsetDateTime utc(LocalDateTime value) {
        return value == null ? null : value.atOffset(ZoneOffset.UTC);
    }
}
