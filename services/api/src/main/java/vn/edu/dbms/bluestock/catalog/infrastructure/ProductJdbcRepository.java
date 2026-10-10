package vn.edu.dbms.bluestock.catalog.infrastructure;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;
import vn.edu.dbms.bluestock.catalog.application.ProductModels.ProductData;
import vn.edu.dbms.bluestock.catalog.application.ProductModels.ProductPage;
import vn.edu.dbms.bluestock.catalog.application.ProductModels.ProductView;

@Repository
public class ProductJdbcRepository {
    private static final String SELECT = """
        SELECT sp.MaSP, sp.TenSP, sp.MaLoai, loai.TenLoai,
               sp.MaDVT, dvt.TenDVT, sp.GiaNhapMacDinh, sp.GiaBanMacDinh
        FROM dbo.SAN_PHAM sp
        JOIN dbo.LOAI_SAN_PHAM loai ON loai.MaLoai = sp.MaLoai
        JOIN dbo.DON_VI_TINH dvt ON dvt.MaDVT = sp.MaDVT
        """;
    private static final RowMapper<ProductView> PRODUCT_MAPPER = (row, index) -> new ProductView(
        row.getString("MaSP").trim(),
        row.getString("TenSP"),
        row.getString("MaLoai").trim(),
        row.getString("TenLoai"),
        row.getString("MaDVT").trim(),
        row.getString("TenDVT"),
        row.getBigDecimal("GiaNhapMacDinh"),
        row.getBigDecimal("GiaBanMacDinh")
    );

    private final JdbcTemplate jdbc;

    public ProductJdbcRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public ProductPage findPage(int page, int size, String query) {
        String where = query == null ? "" :
            "WHERE CHARINDEX(?, sp.MaSP) > 0 OR CHARINDEX(?, sp.TenSP) > 0 ";
        var args = new ArrayList<Object>();
        if (query != null) {
            args.add(query);
            args.add(query);
        }
        Integer count = jdbc.queryForObject(
            "SELECT COUNT(*) FROM dbo.SAN_PHAM sp " + where,
            Integer.class,
            args.toArray());
        args.add(page * size);
        args.add(size);
        List<ProductView> items = jdbc.query(
            SELECT + where + "ORDER BY sp.MaSP OFFSET ? ROWS FETCH NEXT ? ROWS ONLY",
            PRODUCT_MAPPER,
            args.toArray());
        long total = count == null ? 0 : count.longValue();
        long pages = (total + size - 1) / size;
        return new ProductPage(items, page, size, total, pages);
    }

    public Optional<ProductView> findByCode(String code) {
        return jdbc.query(SELECT + "WHERE sp.MaSP = ?", PRODUCT_MAPPER, code)
            .stream().findFirst();
    }

    public boolean categoryExists(String code) {
        Integer count = jdbc.queryForObject(
            "SELECT COUNT(*) FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = ?", Integer.class, code);
        return count != null && count > 0;
    }

    public boolean unitExists(String code) {
        Integer count = jdbc.queryForObject(
            "SELECT COUNT(*) FROM dbo.DON_VI_TINH WHERE MaDVT = ?", Integer.class, code);
        return count != null && count > 0;
    }

    public void insert(String code, String category, String unit, ProductData data) {
        jdbc.update("""
            INSERT INTO dbo.SAN_PHAM
                (MaSP, TenSP, MaLoai, MaDVT, GiaNhapMacDinh, GiaBanMacDinh)
            VALUES (?, ?, ?, ?, ?, ?)
            """, code, data.tenSanPham(), category, unit,
            data.giaNhapMacDinh(), data.giaBanMacDinh());
    }

    public int update(String code, ProductData data) {
        return jdbc.update("""
            UPDATE dbo.SAN_PHAM
            SET TenSP = ?, GiaNhapMacDinh = ?, GiaBanMacDinh = ?
            WHERE MaSP = ?
            """, data.tenSanPham(), data.giaNhapMacDinh(), data.giaBanMacDinh(), code);
    }

    public int delete(String code) {
        return jdbc.update("DELETE FROM dbo.SAN_PHAM WHERE MaSP = ?", code);
    }
}
