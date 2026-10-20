package vn.edu.dbms.bluestock.warehouse.infrastructure;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseModels.AreaView;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseModels.Page;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseModels.PositionView;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseModels.WarehouseView;

@Repository
public class WarehouseJdbcRepository {
    private static final RowMapper<WarehouseView> WAREHOUSE_MAPPER = (row, index) ->
        new WarehouseView(row.getString("MaKho").trim(), row.getString("TenKho"),
            row.getString("DiaChi"));
    private static final RowMapper<AreaView> AREA_MAPPER = (row, index) ->
        new AreaView(row.getString("MaKhuVuc").trim(), row.getString("MaKho").trim(),
            row.getString("TenKho"), row.getString("TenKhuVuc"), row.getString("LoaiKhuVuc"));
    private static final String AREA_SELECT = """
        SELECT kv.MaKhuVuc, kv.MaKho, kho.TenKho, kv.TenKhuVuc, kv.LoaiKhuVuc
        FROM dbo.KHU_VUC kv JOIN dbo.KHO kho ON kho.MaKho = kv.MaKho
        """;
    private static final String POSITION_SELECT = """
        SELECT vt.MaViTri, vt.MaKhuVuc, kv.TenKhuVuc, kv.MaKho, kho.TenKho,
               vt.TenViTri, vt.SucChua, vt.LoaiViTri, kv.LoaiKhuVuc
        FROM dbo.VI_TRI_KHO vt
        JOIN dbo.KHU_VUC kv ON kv.MaKhuVuc = vt.MaKhuVuc
        JOIN dbo.KHO kho ON kho.MaKho = kv.MaKho
        """;
    private static final RowMapper<PositionView> POSITION_MAPPER = (row, index) ->
        new PositionView(row.getString("MaViTri").trim(), row.getString("MaKhuVuc").trim(),
            row.getString("TenKhuVuc"), row.getString("MaKho").trim(),
            row.getString("TenKho"), row.getString("TenViTri"), row.getInt("SucChua"),
            row.getString("LoaiViTri"), row.getString("LoaiKhuVuc"));

    private final JdbcTemplate jdbc;

    public WarehouseJdbcRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Page<WarehouseView> warehouses(int page, int size, String query) {
        String where = query == null ? "" :
            "WHERE CHARINDEX(?, MaKho) > 0 OR CHARINDEX(?, TenKho) > 0 ";
        var args = searchArgs(query);
        long count = count("SELECT COUNT(*) FROM dbo.KHO " + where, args);
        args.add(page * size);
        args.add(size);
        List<WarehouseView> items = jdbc.query("""
            SELECT MaKho, TenKho, DiaChi FROM dbo.KHO
            """ + where + "ORDER BY MaKho OFFSET ? ROWS FETCH NEXT ? ROWS ONLY",
            WAREHOUSE_MAPPER, args.toArray());
        return new Page<>(items, page, size, count, (count + size - 1) / size);
    }

    public Page<AreaView> areas(int page, int size, String warehouseCode, String query) {
        var clauses = new ArrayList<String>();
        var args = new ArrayList<Object>();
        if (warehouseCode != null) {
            clauses.add("kv.MaKho = ?");
            args.add(warehouseCode);
        }
        if (query != null) {
            clauses.add("(CHARINDEX(?, kv.MaKhuVuc) > 0 OR CHARINDEX(?, kv.TenKhuVuc) > 0)");
            args.add(query);
            args.add(query);
        }
        String where = clauses.isEmpty() ? "" : "WHERE " + String.join(" AND ", clauses) + " ";
        long count = count("SELECT COUNT(*) FROM dbo.KHU_VUC kv " + where, args);
        args.add(page * size);
        args.add(size);
        List<AreaView> items = jdbc.query(AREA_SELECT + where +
            "ORDER BY kv.MaKhuVuc OFFSET ? ROWS FETCH NEXT ? ROWS ONLY",
            AREA_MAPPER, args.toArray());
        return new Page<>(items, page, size, count, (count + size - 1) / size);
    }

    public Page<PositionView> positions(int page, int size, String warehouseCode,
        String areaCode, String query) {
        var clauses = new ArrayList<String>();
        var args = new ArrayList<Object>();
        if (warehouseCode != null) {
            clauses.add("kv.MaKho = ?");
            args.add(warehouseCode);
        }
        if (areaCode != null) {
            clauses.add("vt.MaKhuVuc = ?");
            args.add(areaCode);
        }
        if (query != null) {
            clauses.add("(CHARINDEX(?, vt.MaViTri) > 0 OR CHARINDEX(?, vt.TenViTri) > 0)");
            args.add(query);
            args.add(query);
        }
        String where = clauses.isEmpty() ? "" : "WHERE " + String.join(" AND ", clauses) + " ";
        long count = count("""
            SELECT COUNT(*) FROM dbo.VI_TRI_KHO vt
            JOIN dbo.KHU_VUC kv ON kv.MaKhuVuc = vt.MaKhuVuc
            """ + where, args);
        args.add(page * size);
        args.add(size);
        List<PositionView> items = jdbc.query(POSITION_SELECT + where +
            "ORDER BY vt.MaViTri OFFSET ? ROWS FETCH NEXT ? ROWS ONLY",
            POSITION_MAPPER, args.toArray());
        return new Page<>(items, page, size, count, (count + size - 1) / size);
    }

    public Optional<WarehouseView> warehouse(String code) {
        return jdbc.query("SELECT MaKho, TenKho, DiaChi FROM dbo.KHO WHERE MaKho = ?",
            WAREHOUSE_MAPPER, code).stream().findFirst();
    }

    public Optional<AreaView> area(String code) {
        return jdbc.query(AREA_SELECT + "WHERE kv.MaKhuVuc = ?", AREA_MAPPER, code)
            .stream().findFirst();
    }

    public Optional<PositionView> position(String code) {
        return jdbc.query(POSITION_SELECT + "WHERE vt.MaViTri = ?", POSITION_MAPPER, code)
            .stream().findFirst();
    }

    public void insertWarehouse(String code, String name, String address) {
        jdbc.update("INSERT INTO dbo.KHO (MaKho, TenKho, DiaChi) VALUES (?, ?, ?)",
            code, name, address);
    }

    public int updateWarehouse(String code, String name, String address) {
        return jdbc.update("UPDATE dbo.KHO SET TenKho = ?, DiaChi = ? WHERE MaKho = ?",
            name, address, code);
    }

    public int deleteWarehouse(String code) {
        return jdbc.update("DELETE FROM dbo.KHO WHERE MaKho = ?", code);
    }

    public void insertArea(String code, String warehouseCode, String name, String type) {
        jdbc.update("""
            INSERT INTO dbo.KHU_VUC (MaKhuVuc, MaKho, TenKhuVuc, LoaiKhuVuc)
            VALUES (?, ?, ?, ?)
            """, code, warehouseCode, name, type);
    }

    public int updateArea(String code, String name) {
        return jdbc.update("UPDATE dbo.KHU_VUC SET TenKhuVuc = ? WHERE MaKhuVuc = ?",
            name, code);
    }

    public int deleteArea(String code) {
        return jdbc.update("DELETE FROM dbo.KHU_VUC WHERE MaKhuVuc = ?", code);
    }

    public void insertPosition(String code, String areaCode, String name, int capacity, String type) {
        jdbc.update("""
            INSERT INTO dbo.VI_TRI_KHO (MaViTri, MaKhuVuc, TenViTri, SucChua, LoaiViTri)
            VALUES (?, ?, ?, ?, ?)
            """, code, areaCode, name, capacity, type);
    }

    public int updatePosition(String code, String name) {
        return jdbc.update("UPDATE dbo.VI_TRI_KHO SET TenViTri = ? WHERE MaViTri = ?", name, code);
    }

    public int deletePosition(String code) {
        return jdbc.update("DELETE FROM dbo.VI_TRI_KHO WHERE MaViTri = ?", code);
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
