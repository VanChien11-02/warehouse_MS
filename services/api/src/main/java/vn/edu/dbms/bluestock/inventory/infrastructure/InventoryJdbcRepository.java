package vn.edu.dbms.bluestock.inventory.infrastructure;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import vn.edu.dbms.bluestock.inventory.application.InventoryModels.StockFilter;
import vn.edu.dbms.bluestock.inventory.application.AvailableStockQuery;
import vn.edu.dbms.bluestock.inventory.application.AvailableStockQuery.StockCandidate;
import vn.edu.dbms.bluestock.inventory.application.InventoryModels.StockPage;
import vn.edu.dbms.bluestock.inventory.application.InventoryModels.StockView;

@Repository
public class InventoryJdbcRepository implements AvailableStockQuery {
    private final JdbcTemplate jdbc;

    public InventoryJdbcRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public StockPage findPage(int page, int size, StockFilter filter, LocalDate businessDate) {
        var where = new StringBuilder("WHERE SoLuongTon > 0 ");
        var args = new ArrayList<Object>();
        addCodeFilter(where, args, "MaKho", filter.maKho());
        addCodeFilter(where, args, "MaViTri", filter.maViTri());
        addCodeFilter(where, args, "MaSP", filter.maSanPham());
        addCodeFilter(where, args, "MaLo", filter.maLo());
        if (filter.hanSuDungTruoc() != null) {
            where.append("AND HanSuDung <= ? ");
            args.add(filter.hanSuDungTruoc());
        }
        if (filter.chiKhaDung()) {
            where.append("AND LoaiViTri <> N'Hư hỏng' AND (HanSuDung IS NULL OR HanSuDung >= ?) ");
            args.add(businessDate);
        }
        Long count = jdbc.queryForObject("SELECT COUNT(*) FROM dbo.vw_TonKhoChiTiet " + where,
            Long.class, args.toArray());
        long total = count == null ? 0 : count;
        args.add(page * size);
        args.add(size);
        List<StockView> items = jdbc.query("""
            SELECT MaKho, TenKho, MaKhuVuc, TenKhuVuc, MaViTri, TenViTri, LoaiViTri,
                   MaLo, MaSP, TenSP, MaDVT, SoLuongTon, NgaySanXuat, HanSuDung,
                   MaPN, NgayHoanTat, DonGiaNhap
            FROM dbo.vw_TonKhoChiTiet
            """ + where + """
            ORDER BY MaSP, CASE WHEN HanSuDung IS NULL THEN 1 ELSE 0 END,
                     HanSuDung, MaViTri, MaLo
            OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
            """, (row, index) -> {
                int quantity = row.getInt("SoLuongTon");
                BigDecimal unitPrice = row.getBigDecimal("DonGiaNhap");
                java.sql.Date expiry = row.getDate("HanSuDung");
                LocalDate expiryDate = expiry == null ? null : expiry.toLocalDate();
                java.sql.Date production = row.getDate("NgaySanXuat");
                boolean available = !"Hư hỏng".equals(row.getString("LoaiViTri"))
                    && (expiryDate == null || !expiryDate.isBefore(businessDate));
                return new StockView(row.getString("MaKho").trim(), row.getString("TenKho"),
                    row.getString("MaKhuVuc").trim(), row.getString("TenKhuVuc"),
                    row.getString("MaViTri").trim(), row.getString("TenViTri"),
                    row.getString("LoaiViTri"), row.getString("MaLo").trim(),
                    row.getString("MaSP").trim(), row.getString("TenSP"),
                    row.getString("MaDVT").trim(), quantity,
                    production == null ? null : production.toLocalDate(), expiryDate,
                    row.getString("MaPN").trim(),
                    row.getObject("NgayHoanTat", LocalDateTime.class).atOffset(ZoneOffset.UTC),
                    unitPrice, unitPrice.multiply(BigDecimal.valueOf(quantity)), available);
            }, args.toArray());
        return new StockPage(items, page, size, total, (total + size - 1) / size);
    }

    @Override
    public List<StockCandidate> findAvailable(String productCode, String warehouseCode,
        LocalDate businessDate) {
        var sql = new StringBuilder("""
            SELECT MaLo, MaViTri, SoLuongTon, HanSuDung
            FROM dbo.vw_TonKhoChiTiet
            WHERE MaSP = ? AND SoLuongTon > 0 AND LoaiViTri <> N'Hư hỏng'
              AND (HanSuDung IS NULL OR HanSuDung >= ?)
            """);
        var args = new ArrayList<Object>();
        args.add(productCode);
        args.add(businessDate);
        if (warehouseCode != null) {
            sql.append("AND MaKho = ? ");
            args.add(warehouseCode);
        }
        sql.append("""
            ORDER BY CASE WHEN HanSuDung IS NULL THEN 1 ELSE 0 END,
                     HanSuDung, MaLo, MaViTri
            """);
        return jdbc.query(sql.toString(), (row, index) -> {
            java.sql.Date expiry = row.getDate("HanSuDung");
            return new StockCandidate(row.getString("MaLo").trim(),
                row.getString("MaViTri").trim(), row.getInt("SoLuongTon"),
                expiry == null ? null : expiry.toLocalDate());
        }, args.toArray());
    }

    private static void addCodeFilter(StringBuilder where, List<Object> args, String column, String code) {
        if (code != null) {
            where.append("AND ").append(column).append(" = ? ");
            args.add(code);
        }
    }
}
