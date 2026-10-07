package vn.edu.dbms.bluestock.reporting.infrastructure;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;
import vn.edu.dbms.bluestock.reporting.application.ReportingModels.MovementReportPage;
import vn.edu.dbms.bluestock.reporting.application.ReportingModels.MovementReportRow;
import vn.edu.dbms.bluestock.reporting.application.ReportingModels.CountDiscrepancyPage;
import vn.edu.dbms.bluestock.reporting.application.ReportingModels.CountDiscrepancyRow;

@Repository
public class ReportingJdbcRepository {
    private static final String SOURCE = """
        FROM dbo.vw_BienDongTonKhoChiTiet
        WHERE NgayGhiSo < :endUtc
        """;
    private static final String REPORT = """
        SELECT MaKho, TenKho, MaSP, TenSP, MaDVT,
            SUM(CASE WHEN NgayGhiSo < :startUtc
                THEN CONVERT(BIGINT, SoLuongThayDoi) ELSE CONVERT(BIGINT, 0) END) AS SoLuongDauKy,
            SUM(CASE WHEN NgayGhiSo >= :startUtc AND LoaiNghiepVu = N'NHAP'
                THEN CONVERT(BIGINT, SoLuongThayDoi) ELSE CONVERT(BIGINT, 0) END) AS SoLuongNhap,
            -SUM(CASE WHEN NgayGhiSo >= :startUtc AND LoaiNghiepVu = N'XUAT'
                THEN CONVERT(BIGINT, SoLuongThayDoi) ELSE CONVERT(BIGINT, 0) END) AS SoLuongXuat,
            SUM(CASE WHEN NgayGhiSo >= :startUtc
                AND LoaiNghiepVu NOT IN (N'NHAP', N'XUAT')
                THEN CONVERT(BIGINT, SoLuongThayDoi) ELSE CONVERT(BIGINT, 0) END) AS SoLuongDieuChinh,
            SUM(CONVERT(BIGINT, SoLuongThayDoi)) AS SoLuongCuoiKy,
            SUM(CASE WHEN NgayGhiSo < :startUtc THEN GiaTriThayDoi ELSE 0 END) AS GiaTriDauKy,
            SUM(CASE WHEN NgayGhiSo >= :startUtc AND LoaiNghiepVu = N'NHAP'
                THEN GiaTriThayDoi ELSE 0 END) AS GiaTriNhap,
            -SUM(CASE WHEN NgayGhiSo >= :startUtc AND LoaiNghiepVu = N'XUAT'
                THEN GiaTriThayDoi ELSE 0 END) AS GiaTriXuat,
            SUM(CASE WHEN NgayGhiSo >= :startUtc
                AND LoaiNghiepVu NOT IN (N'NHAP', N'XUAT')
                THEN GiaTriThayDoi ELSE 0 END) AS GiaTriDieuChinh,
            SUM(GiaTriThayDoi) AS GiaTriCuoiKy
        """;
    private static final String COUNT_SOURCE = """
        FROM dbo.vw_ChenhLechKiemKe
        WHERE NgayHoanTat >= :startUtc AND NgayHoanTat < :endUtc
        """;

    private final NamedParameterJdbcTemplate jdbc;

    public ReportingJdbcRepository(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public MovementReportPage movementReport(LocalDate from, LocalDate through,
        LocalDateTime startUtc, LocalDateTime endUtc,
        String warehouseCode, String productCode, int page, int size) {
        var params = new MapSqlParameterSource()
            .addValue("startUtc", startUtc)
            .addValue("endUtc", endUtc);
        var filters = new ArrayList<String>();
        if (warehouseCode != null) {
            filters.add("MaKho = :maKho");
            params.addValue("maKho", warehouseCode);
        }
        if (productCode != null) {
            filters.add("MaSP = :maSanPham");
            params.addValue("maSanPham", productCode);
        }
        String where = SOURCE + (filters.isEmpty() ? "" : "AND " + String.join(" AND ", filters) + "\n");
        String groups = "GROUP BY MaKho, TenKho, MaSP, TenSP, MaDVT\n";
        Long count = jdbc.queryForObject("""
            SELECT COUNT_BIG(*) FROM (
                SELECT MaKho, MaSP
            """ + where + "GROUP BY MaKho, MaSP) grouped", params, Long.class);
        long total = count == null ? 0 : count;
        params.addValue("offset", page * size);
        params.addValue("size", size);
        List<MovementReportRow> rows = jdbc.query("""
            SELECT * FROM (
            """ + REPORT + where + groups + """
            ) report ORDER BY MaKho, MaSP
            OFFSET :offset ROWS FETCH NEXT :size ROWS ONLY
            """, params, (row, index) -> new MovementReportRow(
                row.getString("MaKho").trim(), row.getString("TenKho"),
                row.getString("MaSP").trim(), row.getString("TenSP"),
                row.getString("MaDVT").trim(), row.getLong("SoLuongDauKy"),
                row.getLong("SoLuongNhap"), row.getLong("SoLuongXuat"),
                row.getLong("SoLuongDieuChinh"), row.getLong("SoLuongCuoiKy"),
                row.getBigDecimal("GiaTriDauKy"), row.getBigDecimal("GiaTriNhap"),
                row.getBigDecimal("GiaTriXuat"), row.getBigDecimal("GiaTriDieuChinh"),
                row.getBigDecimal("GiaTriCuoiKy")));
        return new MovementReportPage(from, through, rows, page, size,
            total, (total + size - 1) / size);
    }

    public CountDiscrepancyPage countDiscrepancies(LocalDate from, LocalDate through,
        LocalDateTime startUtc, LocalDateTime endUtc,
        String warehouseCode, String positionCode, int page, int size) {
        var params = new MapSqlParameterSource()
            .addValue("startUtc", startUtc)
            .addValue("endUtc", endUtc);
        var filters = new ArrayList<String>();
        if (warehouseCode != null) {
            filters.add("MaKho = :maKho");
            params.addValue("maKho", warehouseCode);
        }
        if (positionCode != null) {
            filters.add("MaViTri = :maViTri");
            params.addValue("maViTri", positionCode);
        }
        String where = COUNT_SOURCE
            + (filters.isEmpty() ? "" : "AND " + String.join(" AND ", filters) + "\n");
        Long count = jdbc.queryForObject("SELECT COUNT_BIG(*) " + where, params, Long.class);
        long total = count == null ? 0 : count;
        params.addValue("offset", page * size);
        params.addValue("size", size);
        List<CountDiscrepancyRow> rows = jdbc.query("""
            SELECT MaPKK, MaKho, MaViTri, MaLo, MaSP, TenSP,
                   SoLuongHeThong, SoLuongThucTe, ChenhLech, LyDoChenhLech,
                   NgayHoanTat
            """ + where + "ORDER BY NgayHoanTat DESC, MaPKK DESC, MaLo "
            + "OFFSET :offset ROWS FETCH NEXT :size ROWS ONLY", params, (row, index) -> {
                long system = row.getLong("SoLuongHeThong");
                long actual = row.getLong("SoLuongThucTe");
                return new CountDiscrepancyRow(row.getString("MaPKK").trim(),
                    row.getString("MaKho").trim(), row.getString("MaViTri").trim(),
                    row.getString("MaLo").trim(), row.getString("MaSP").trim(),
                    row.getString("TenSP"), system, actual, row.getLong("ChenhLech"),
                    row.getString("LyDoChenhLech"),
                    row.getObject("NgayHoanTat", LocalDateTime.class).atOffset(ZoneOffset.UTC));
            });
        return new CountDiscrepancyPage(from, through, rows, page, size,
            total, (total + size - 1) / size);
    }
}
