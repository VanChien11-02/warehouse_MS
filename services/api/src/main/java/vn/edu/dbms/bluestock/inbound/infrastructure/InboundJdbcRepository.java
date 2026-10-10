package vn.edu.dbms.bluestock.inbound.infrastructure;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.CompletionView;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.InboundView;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.InboundSummary;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.InboundPage;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.LineData;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.LineView;

@Repository
public class InboundJdbcRepository {
    private final JdbcTemplate jdbc;

    public InboundJdbcRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public int nextCodeNumber() {
        Integer number = jdbc.queryForObject("SELECT NEXT VALUE FOR dbo.SEQ_PHIEU_NHAP", Integer.class);
        if (number == null) throw new IllegalStateException("Không cấp được mã phiếu nhập");
        return number;
    }

    public void insertHeader(String code, String supplier, String employee, String note) {
        jdbc.update("""
            INSERT INTO dbo.PHIEU_NHAP (MaPN, MaNCC, MaNV, GhiChu) VALUES (?, ?, ?, ?)
            """, code, supplier, employee, note);
    }

    public void insertLine(String code, LineData line) {
        jdbc.update("""
            INSERT INTO dbo.CT_PHIEU_NHAP (MaPN, MaSP, SoLuong, DonGiaNhap)
            VALUES (?, ?, ?, ?)
            """, code, line.maSanPham(), line.soLuong(), line.donGiaNhap());
    }

    public InboundPage findPage(int page, int size, String status, String supplier) {
        var clauses = new ArrayList<String>();
        var args = new ArrayList<Object>();
        if (status != null) {
            clauses.add("pn.TrangThai = ?");
            args.add(status);
        }
        if (supplier != null) {
            clauses.add("pn.MaNCC = ?");
            args.add(supplier);
        }
        String where = clauses.isEmpty() ? "" : "WHERE " + String.join(" AND ", clauses) + " ";
        Long count = jdbc.queryForObject("SELECT COUNT_BIG(*) FROM dbo.PHIEU_NHAP pn " + where,
            Long.class, args.toArray());
        args.add(page * size);
        args.add(size);
        List<InboundSummary> items = jdbc.query("""
            SELECT pn.MaPN, pn.NgayNhap, pn.MaNCC, ncc.TenNCC, pn.MaNV,
                   pn.TrangThai, pn.GhiChu, pn.NgayHoanTat
            FROM dbo.PHIEU_NHAP pn
            JOIN dbo.NHA_CUNG_CAP ncc ON ncc.MaNCC = pn.MaNCC
            """ + where + "ORDER BY pn.NgayNhap DESC, pn.MaPN DESC "
            + "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY", (row, index) ->
                new InboundSummary(row.getString("MaPN").trim(),
                    utc(row.getObject("NgayNhap", LocalDateTime.class)),
                    row.getString("MaNCC").trim(), row.getString("TenNCC"),
                    row.getString("MaNV").trim(), row.getString("TrangThai"),
                    row.getString("GhiChu"), utc(row.getObject("NgayHoanTat", LocalDateTime.class))),
            args.toArray());
        long total = count == null ? 0 : count;
        return new InboundPage(items, page, size, total, (total + size - 1) / size);
    }

    public Optional<String> lockedStatus(String code) {
        return jdbc.queryForList("""
            SELECT TrangThai FROM dbo.PHIEU_NHAP WITH (UPDLOCK, HOLDLOCK) WHERE MaPN = ?
            """, String.class, code).stream().findFirst();
    }

    public void updateHeader(String code, String supplier, String note) {
        jdbc.update("UPDATE dbo.PHIEU_NHAP SET MaNCC = ?, GhiChu = ? WHERE MaPN = ?",
            supplier, note, code);
    }

    public void replaceLines(String code, List<LineData> lines) {
        jdbc.update("DELETE FROM dbo.CT_PHIEU_NHAP WHERE MaPN = ?", code);
        for (LineData line : lines) insertLine(code, line);
    }

    public void cancel(String code) {
        jdbc.update("UPDATE dbo.PHIEU_NHAP SET TrangThai = N'DA_HUY' WHERE MaPN = ?", code);
    }

    public Optional<InboundView> findByCode(String code) {
        List<InboundView> headers = jdbc.query("""
            SELECT pn.MaPN, pn.NgayNhap, pn.MaNCC, ncc.TenNCC, pn.MaNV,
                   pn.TrangThai, pn.GhiChu, pn.NgayHoanTat
            FROM dbo.PHIEU_NHAP pn
            JOIN dbo.NHA_CUNG_CAP ncc ON ncc.MaNCC = pn.MaNCC
            WHERE pn.MaPN = ?
            """, (row, index) -> new InboundView(
                row.getString("MaPN").trim(), utc(row.getObject("NgayNhap", LocalDateTime.class)),
                row.getString("MaNCC").trim(), row.getString("TenNCC"),
                row.getString("MaNV").trim(), row.getString("TrangThai"),
                row.getString("GhiChu"), utc(row.getObject("NgayHoanTat", LocalDateTime.class)),
                List.of()), code);
        if (headers.isEmpty()) return Optional.empty();
        List<LineView> lines = jdbc.query("""
            SELECT ct.MaSP, sp.TenSP, ct.SoLuong, ct.DonGiaNhap
            FROM dbo.CT_PHIEU_NHAP ct
            JOIN dbo.SAN_PHAM sp ON sp.MaSP = ct.MaSP
            WHERE ct.MaPN = ? ORDER BY ct.MaSP
            """, (row, index) -> new LineView(row.getString("MaSP").trim(),
                row.getString("TenSP"), row.getInt("SoLuong"), row.getBigDecimal("DonGiaNhap")),
            code);
        InboundView header = headers.getFirst();
        return Optional.of(new InboundView(header.maPhieuNhap(), header.ngayNhap(),
            header.maNhaCungCap(), header.tenNhaCungCap(), header.maNhanVien(),
            header.trangThai(), header.ghiChu(), header.ngayHoanTat(), lines));
    }

    public CompletionView complete(String code, String allocationsJson) {
        return jdbc.queryForObject("EXEC dbo.sp_HoanTatPhieuNhap @MaPN = ?, @PhanBoJson = ?",
            (row, index) -> new CompletionView(row.getString("maPhieuNhap").trim(),
                row.getString("trangThai"), utc(row.getObject("ngayHoanTat", LocalDateTime.class))),
            code, allocationsJson);
    }

    private static OffsetDateTime utc(LocalDateTime value) {
        return value == null ? null : value.atOffset(ZoneOffset.UTC);
    }
}
