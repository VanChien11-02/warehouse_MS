package vn.edu.dbms.bluestock.partner.infrastructure;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;
import vn.edu.dbms.bluestock.partner.application.PartnerModels.Page;
import vn.edu.dbms.bluestock.partner.application.PartnerModels.RecipientView;
import vn.edu.dbms.bluestock.partner.application.PartnerModels.SupplierView;

@Repository
public class PartnerJdbcRepository {
    private static final RowMapper<SupplierView> SUPPLIER_MAPPER = (row, index) ->
        new SupplierView(row.getString("MaNCC").trim(), row.getString("TenNCC"),
            row.getString("DiaChi"), row.getString("SDT"), row.getString("Email"));
    private static final RowMapper<RecipientView> RECIPIENT_MAPPER = (row, index) ->
        new RecipientView(row.getString("MaDTNH").trim(), row.getString("TenDoiTac"),
            row.getString("LoaiDoiTac"), row.getString("DiaChi"),
            row.getString("SDT"), row.getString("Email"));

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

    public String nextSupplierCode() {
        Integer next = jdbc.queryForObject("""
            SELECT COALESCE(MAX(TRY_CAST(SUBSTRING(RTRIM(MaNCC), 4, 10) AS INT)), 0) + 1
            FROM dbo.NHA_CUNG_CAP WHERE MaNCC LIKE 'NCC%'
            """, Integer.class);
        return String.format("NCC%03d", Math.min(999, next == null ? 1 : next));
    }

    public String nextRecipientCode() {
        Integer next = jdbc.queryForObject("""
            SELECT COALESCE(MAX(TRY_CAST(SUBSTRING(RTRIM(MaDTNH), 3, 10) AS INT)), 0) + 1
            FROM dbo.DOI_TAC_NHAN_HANG WHERE MaDTNH LIKE 'DT%'
            """, Integer.class);
        return String.format("DT%04d", Math.min(9999, next == null ? 1 : next));
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

    public Page<RecipientView> recipients(int page, int size, String query) {
        String where = query == null ? "" :
            "WHERE CHARINDEX(?, MaDTNH) > 0 OR CHARINDEX(?, TenDoiTac) > 0 ";
        var args = new ArrayList<Object>();
        if (query != null) {
            args.add(query);
            args.add(query);
        }
        Long count = jdbc.queryForObject("SELECT COUNT_BIG(*) FROM dbo.DOI_TAC_NHAN_HANG " + where,
            Long.class, args.toArray());
        args.add(page * size);
        args.add(size);
        List<RecipientView> items = jdbc.query("""
            SELECT MaDTNH, TenDoiTac, LoaiDoiTac, DiaChi, SDT, Email FROM dbo.DOI_TAC_NHAN_HANG
            """ + where + "ORDER BY MaDTNH OFFSET ? ROWS FETCH NEXT ? ROWS ONLY",
            RECIPIENT_MAPPER, args.toArray());
        long total = count == null ? 0 : count;
        return new Page<>(items, page, size, total, (total + size - 1) / size);
    }

    public Optional<RecipientView> recipient(String code) {
        return jdbc.query("""
            SELECT MaDTNH, TenDoiTac, LoaiDoiTac, DiaChi, SDT, Email
            FROM dbo.DOI_TAC_NHAN_HANG WHERE MaDTNH = ?
            """, RECIPIENT_MAPPER, code).stream().findFirst();
    }

    public void insertRecipient(String code, String name, String type, String address,
        String phone, String email) {
        jdbc.update("""
            INSERT INTO dbo.DOI_TAC_NHAN_HANG (MaDTNH, TenDoiTac, LoaiDoiTac, DiaChi, SDT, Email)
            VALUES (?, ?, ?, ?, ?, ?)
            """, code, name, type, address, phone, email);
    }

    public int updateRecipient(String code, String name, String type, String address,
        String phone, String email) {
        return jdbc.update("""
            UPDATE dbo.DOI_TAC_NHAN_HANG
            SET TenDoiTac = ?, LoaiDoiTac = ?, DiaChi = ?, SDT = ?, Email = ?
            WHERE MaDTNH = ?
            """, name, type, address, phone, email, code);
    }

    public int deleteRecipient(String code) {
        return jdbc.update("DELETE FROM dbo.DOI_TAC_NHAN_HANG WHERE MaDTNH = ?", code);
    }

    public List<String> recipientProducts(String code) {
        return jdbc.queryForList("""
            SELECT MaSP FROM dbo.DOI_TAC_SAN_PHAM WHERE MaDTNH = ? ORDER BY MaSP
            """, String.class, code).stream().map(String::trim).toList();
    }

    public void addRecipientProduct(String recipientCode, String productCode) {
        jdbc.update("""
            INSERT INTO dbo.DOI_TAC_SAN_PHAM (MaDTNH, MaSP) VALUES (?, ?)
            """, recipientCode, productCode);
    }

    public int removeRecipientProduct(String recipientCode, String productCode) {
        return jdbc.update("""
            DELETE FROM dbo.DOI_TAC_SAN_PHAM WHERE MaDTNH = ? AND MaSP = ?
            """, recipientCode, productCode);
    }
}
