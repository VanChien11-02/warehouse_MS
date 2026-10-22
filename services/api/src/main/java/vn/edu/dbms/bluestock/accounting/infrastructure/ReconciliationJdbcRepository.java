package vn.edu.dbms.bluestock.accounting.infrastructure;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Optional;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import vn.edu.dbms.bluestock.accounting.application.ReconciliationModels.ReconciliationView;

@Repository
public class ReconciliationJdbcRepository {
    private final JdbcTemplate jdbc;

    public ReconciliationJdbcRepository(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    public Optional<String> lockedDocumentStatus(String type, String code) {
        String table = type.equals("NHAP") ? "PHIEU_NHAP" : "PHIEU_XUAT";
        String key = type.equals("NHAP") ? "MaPN" : "MaPX";
        return jdbc.queryForList("SELECT TrangThai FROM dbo." + table
            + " WITH (UPDLOCK, HOLDLOCK) WHERE " + key + " = ?", String.class, code)
            .stream().findFirst();
    }

    public BigDecimal documentValue(String type, String code) {
        String table = type.equals("NHAP") ? "CT_PHIEU_NHAP" : "CT_PHIEU_XUAT";
        String key = type.equals("NHAP") ? "MaPN" : "MaPX";
        String price = type.equals("NHAP") ? "DonGiaNhap" : "DonGiaXuat";
        return jdbc.queryForObject("SELECT CAST(COALESCE(SUM(CAST(SoLuong AS DECIMAL(19,4)) * "
            + price + "), 0) AS DECIMAL(19,4)) FROM dbo." + table + " WHERE " + key + " = ?",
            BigDecimal.class, code);
    }

    public Optional<ReconciliationView> find(String type, String code) {
        return jdbc.query("""
            SELECT LoaiChungTu, MaChungTu, GiaTriChungTu, GiaTriDoiSoat,
                   TrangThai, GhiChu, MaTKKeToan, ThoiGian
            FROM dbo.DOI_SOAT_GIA_TRI WHERE LoaiChungTu = ? AND MaChungTu = ?
            """, (row, index) -> {
                BigDecimal document = row.getBigDecimal("GiaTriChungTu");
                BigDecimal checked = row.getBigDecimal("GiaTriDoiSoat");
                return new ReconciliationView(row.getString("LoaiChungTu"),
                    row.getString("MaChungTu").trim(), document, checked,
                    checked.subtract(document), row.getString("TrangThai"),
                    row.getString("GhiChu"), row.getString("MaTKKeToan").trim(),
                    row.getObject("ThoiGian", LocalDateTime.class).atOffset(ZoneOffset.UTC));
            }, type, code).stream().findFirst();
    }

    public void insert(String type, String code, BigDecimal documentValue,
        BigDecimal checkedValue, String status, String note, String actor) {
        jdbc.update("""
            INSERT INTO dbo.DOI_SOAT_GIA_TRI
                (LoaiChungTu, MaChungTu, GiaTriChungTu, GiaTriDoiSoat, TrangThai, GhiChu, MaTKKeToan)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """, type, code, documentValue, checkedValue, status, note, actor);
    }
}
