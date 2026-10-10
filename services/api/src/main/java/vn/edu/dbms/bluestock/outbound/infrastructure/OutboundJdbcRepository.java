package vn.edu.dbms.bluestock.outbound.infrastructure;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.CompletionView;
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.LineData;
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.LineView;
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.OutboundView;

@Repository
public class OutboundJdbcRepository {
    private final JdbcTemplate jdbc;

    public OutboundJdbcRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public int nextCodeNumber() {
        Integer number = jdbc.queryForObject("SELECT NEXT VALUE FOR dbo.SEQ_PHIEU_XUAT", Integer.class);
        if (number == null) throw new IllegalStateException("Không cấp được mã phiếu xuất");
        return number;
    }

    public void insertHeader(String code, String recipient, String employee, String note) {
        jdbc.update("""
            INSERT INTO dbo.PHIEU_XUAT (MaPX, MaDTNH, MaNV, GhiChu) VALUES (?, ?, ?, ?)
            """, code, recipient, employee, note);
    }

    public void insertLine(String code, LineData line) {
        jdbc.update("""
            INSERT INTO dbo.CT_PHIEU_XUAT (MaPX, MaLo, MaViTri, SoLuong, DonGiaXuat)
            VALUES (?, ?, ?, ?, ?)
            """, code, line.maLo(), line.maViTri(), line.soLuong(), line.donGiaXuat());
    }

    public Optional<OutboundView> findByCode(String code) {
        List<OutboundView> headers = jdbc.query("""
            SELECT px.MaPX, px.NgayXuat, px.MaDTNH, dt.TenDoiTac, px.MaNV,
                   px.TrangThai, px.GhiChu, px.NgayHoanTat
            FROM dbo.PHIEU_XUAT px
            JOIN dbo.DOI_TAC_NHAN_HANG dt ON dt.MaDTNH = px.MaDTNH
            WHERE px.MaPX = ?
            """, (row, index) -> new OutboundView(
                row.getString("MaPX").trim(), utc(row.getObject("NgayXuat", LocalDateTime.class)),
                row.getString("MaDTNH").trim(), row.getString("TenDoiTac"),
                row.getString("MaNV").trim(), row.getString("TrangThai"),
                row.getString("GhiChu"), utc(row.getObject("NgayHoanTat", LocalDateTime.class)),
                List.of()), code);
        if (headers.isEmpty()) return Optional.empty();
        List<LineView> lines = jdbc.query("""
            SELECT ct.MaLo, ct.MaViTri, lo.MaSP, sp.TenSP, lo.HanSuDung,
                   ct.SoLuong, ct.DonGiaXuat
            FROM dbo.CT_PHIEU_XUAT ct
            JOIN dbo.LO_HANG lo ON lo.MaLo = ct.MaLo
            JOIN dbo.SAN_PHAM sp ON sp.MaSP = lo.MaSP
            WHERE ct.MaPX = ? ORDER BY ct.MaLo, ct.MaViTri
            """, (row, index) -> {
                java.sql.Date expiry = row.getDate("HanSuDung");
                return new LineView(row.getString("MaLo").trim(), row.getString("MaViTri").trim(),
                    row.getString("MaSP").trim(), row.getString("TenSP"),
                    expiry == null ? null : expiry.toLocalDate(),
                    row.getInt("SoLuong"), row.getBigDecimal("DonGiaXuat"));
            }, code);
        OutboundView header = headers.getFirst();
        return Optional.of(new OutboundView(header.maPhieuXuat(), header.ngayXuat(),
            header.maDoiTacNhanHang(), header.tenDoiTac(), header.maNhanVien(),
            header.trangThai(), header.ghiChu(), header.ngayHoanTat(), lines));
    }

    public CompletionView complete(String code, LocalDate businessDate) {
        return jdbc.queryForObject("EXEC dbo.sp_HoanTatPhieuXuat @MaPX = ?, @NgayNghiepVu = ?",
            (row, index) -> new CompletionView(row.getString("maPhieuXuat").trim(),
                row.getString("trangThai"), utc(row.getObject("ngayHoanTat", LocalDateTime.class))),
            code, businessDate);
    }

    private static OffsetDateTime utc(LocalDateTime value) {
        return value == null ? null : value.atOffset(ZoneOffset.UTC);
    }
}
