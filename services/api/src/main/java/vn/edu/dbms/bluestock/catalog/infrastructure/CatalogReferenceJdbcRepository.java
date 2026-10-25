package vn.edu.dbms.bluestock.catalog.infrastructure;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;
import vn.edu.dbms.bluestock.catalog.application.CatalogReferenceModels.CategoryView;
import vn.edu.dbms.bluestock.catalog.application.CatalogReferenceModels.Page;
import vn.edu.dbms.bluestock.catalog.application.CatalogReferenceModels.UnitView;

@Repository
public class CatalogReferenceJdbcRepository {
    private static final RowMapper<CategoryView> CATEGORY_MAPPER = (row, index) ->
        new CategoryView(row.getString("MaLoai").trim(), row.getString("TenLoai"),
            row.getString("MoTa"), row.getString("YeuCauBaoQuan"));
    private static final RowMapper<UnitView> UNIT_MAPPER = (row, index) ->
        new UnitView(row.getString("MaDVT").trim(), row.getString("TenDVT"));

    private final JdbcTemplate jdbc;

    public CatalogReferenceJdbcRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Page<CategoryView> categories(int page, int size, String query) {
        String where = query == null ? "" : "WHERE CHARINDEX(?, MaLoai) > 0 OR CHARINDEX(?, TenLoai) > 0 ";
        var args = searchArgs(query);
        long count = count("SELECT COUNT(*) FROM dbo.LOAI_SAN_PHAM " + where, args);
        args.add(page * size);
        args.add(size);
        List<CategoryView> items = jdbc.query("""
            SELECT MaLoai, TenLoai, MoTa, YeuCauBaoQuan FROM dbo.LOAI_SAN_PHAM
            """ + where + "ORDER BY MaLoai OFFSET ? ROWS FETCH NEXT ? ROWS ONLY",
            CATEGORY_MAPPER, args.toArray());
        return new Page<>(items, page, size, count, (count + size - 1) / size);
    }

    public Page<UnitView> units(int page, int size, String query) {
        String where = query == null ? "" : "WHERE CHARINDEX(?, MaDVT) > 0 OR CHARINDEX(?, TenDVT) > 0 ";
        var args = searchArgs(query);
        long count = count("SELECT COUNT(*) FROM dbo.DON_VI_TINH " + where, args);
        args.add(page * size);
        args.add(size);
        List<UnitView> items = jdbc.query("""
            SELECT MaDVT, TenDVT FROM dbo.DON_VI_TINH
            """ + where + "ORDER BY MaDVT OFFSET ? ROWS FETCH NEXT ? ROWS ONLY",
            UNIT_MAPPER, args.toArray());
        return new Page<>(items, page, size, count, (count + size - 1) / size);
    }

    public Optional<CategoryView> category(String code) {
        return jdbc.query("""
            SELECT MaLoai, TenLoai, MoTa, YeuCauBaoQuan FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = ?
            """, CATEGORY_MAPPER, code).stream().findFirst();
    }

    public Optional<UnitView> unit(String code) {
        return jdbc.query("SELECT MaDVT, TenDVT FROM dbo.DON_VI_TINH WHERE MaDVT = ?",
            UNIT_MAPPER, code).stream().findFirst();
    }

    public String nextCategoryCode() {
        Integer next = jdbc.queryForObject("""
            SELECT COALESCE(MAX(TRY_CAST(SUBSTRING(RTRIM(MaLoai), 4, 10) AS INT)), 0) + 1
            FROM dbo.LOAI_SAN_PHAM WHERE MaLoai LIKE 'LSP%'
            """, Integer.class);
        return String.format("LSP%03d", Math.min(999, next == null ? 1 : next));
    }

    public String nextUnitCode() {
        Integer next = jdbc.queryForObject("""
            SELECT COALESCE(MAX(TRY_CAST(SUBSTRING(RTRIM(MaDVT), 4, 10) AS INT)), 0) + 1
            FROM dbo.DON_VI_TINH WHERE MaDVT LIKE 'DVT%'
            """, Integer.class);
        return String.format("DVT%03d", Math.min(999, next == null ? 1 : next));
    }

    public void insertCategory(String code, String name, String description, String storageRequirement) {
        jdbc.update("""
            INSERT INTO dbo.LOAI_SAN_PHAM (MaLoai, TenLoai, MoTa, YeuCauBaoQuan)
            VALUES (?, ?, ?, ?)
            """, code, name, description, storageRequirement);
    }

    public int updateCategory(String code, String name, String description, String storageRequirement) {
        return jdbc.update("""
            UPDATE dbo.LOAI_SAN_PHAM SET TenLoai = ?, MoTa = ?, YeuCauBaoQuan = ?
            WHERE MaLoai = ?
            """, name, description, storageRequirement, code);
    }

    public int deleteCategory(String code) {
        return jdbc.update("DELETE FROM dbo.LOAI_SAN_PHAM WHERE MaLoai = ?", code);
    }

    public void insertUnit(String code, String name) {
        jdbc.update("INSERT INTO dbo.DON_VI_TINH (MaDVT, TenDVT) VALUES (?, ?)", code, name);
    }

    public int updateUnit(String code, String name) {
        return jdbc.update("UPDATE dbo.DON_VI_TINH SET TenDVT = ? WHERE MaDVT = ?", name, code);
    }

    public int deleteUnit(String code) {
        return jdbc.update("DELETE FROM dbo.DON_VI_TINH WHERE MaDVT = ?", code);
    }

    private static ArrayList<Object> searchArgs(String query) {
        var args = new ArrayList<Object>();
        if (query != null) {
            args.add(query);
            args.add(query);
        }
        return args;
    }

    private long count(String sql, List<Object> args) {
        Long count = jdbc.queryForObject(sql, Long.class, args.toArray());
        return count == null ? 0 : count;
    }
}
