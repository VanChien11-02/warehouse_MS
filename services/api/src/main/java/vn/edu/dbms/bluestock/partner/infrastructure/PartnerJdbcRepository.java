package vn.edu.dbms.bluestock.partner.infrastructure;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;
import vn.edu.dbms.bluestock.partner.application.PartnerModels.Page;
import vn.edu.dbms.bluestock.partner.application.PartnerModels.SupplierView;

@Repository
public class PartnerJdbcRepository {
    private static final RowMapper<SupplierView> SUPPLIER_MAPPER = (row, index) ->
        new SupplierView(row.getString("MaNCC").trim(), row.getString("TenNCC"),
            row.getString("DiaChi"), row.getString("SDT"), row.getString("Email"));

    private final JdbcTemplate jdbc;

    public PartnerJdbcRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Page<SupplierView> suppliers(int page, int size, String query) {
        String where = query == null ? "" :
            "WHERE CHARINDEX(?, MaNCC) > 0 OR CHARINDEX(?, TenNCC) > 0 ";
        var args = new ArrayList<Object>();
        if (query != null) {
            args.add(query);
            args.add(query);
        }
        Long count = jdbc.queryForObject(
            "SELECT COUNT_BIG(*) FROM dbo.NHA_CUNG_CAP " + where, Long.class, args.toArray());
        args.add(page * size);
        args.add(size);
        List<SupplierView> items = jdbc.query("""
            SELECT MaNCC, TenNCC, DiaChi, SDT, Email FROM dbo.NHA_CUNG_CAP
            """ + where + "ORDER BY MaNCC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY",
            SUPPLIER_MAPPER, args.toArray());
        long total = count == null ? 0 : count;
        return new Page<>(items, page, size, total, (total + size - 1) / size);
    }

    public Optional<SupplierView> supplier(String code) {
        return jdbc.query("""
            SELECT MaNCC, TenNCC, DiaChi, SDT, Email FROM dbo.NHA_CUNG_CAP WHERE MaNCC = ?
            """, SUPPLIER_MAPPER, code).stream().findFirst();
    }

    public void insertSupplier(String code, String name, String address, String phone, String email) {
        jdbc.update("""
            INSERT INTO dbo.NHA_CUNG_CAP (MaNCC, TenNCC, DiaChi, SDT, Email)
            VALUES (?, ?, ?, ?, ?)
            """, code, name, address, phone, email);
    }

    public int updateSupplier(String code, String name, String address, String phone, String email) {
        return jdbc.update("""
            UPDATE dbo.NHA_CUNG_CAP SET TenNCC = ?, DiaChi = ?, SDT = ?, Email = ?
            WHERE MaNCC = ?
            """, name, address, phone, email, code);
    }

    public int deleteSupplier(String code) {
        return jdbc.update("DELETE FROM dbo.NHA_CUNG_CAP WHERE MaNCC = ?", code);
    }

    public List<String> supplierProducts(String code) {
        return jdbc.queryForList("""
            SELECT MaSP FROM dbo.NHA_CUNG_CAP_SAN_PHAM WHERE MaNCC = ? ORDER BY MaSP
            """, String.class, code).stream().map(String::trim).toList();
    }

    public void addSupplierProduct(String supplierCode, String productCode) {
        jdbc.update("""
            INSERT INTO dbo.NHA_CUNG_CAP_SAN_PHAM (MaNCC, MaSP) VALUES (?, ?)
            """, supplierCode, productCode);
    }

    public int removeSupplierProduct(String supplierCode, String productCode) {
        return jdbc.update("""
            DELETE FROM dbo.NHA_CUNG_CAP_SAN_PHAM WHERE MaNCC = ? AND MaSP = ?
            """, supplierCode, productCode);
    }

    public boolean productExists(String code) {
        Boolean exists = jdbc.queryForObject("""
            SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.SAN_PHAM WHERE MaSP = ?) THEN 1 ELSE 0 END
            """, Boolean.class, code);
        return Boolean.TRUE.equals(exists);
    }
}
