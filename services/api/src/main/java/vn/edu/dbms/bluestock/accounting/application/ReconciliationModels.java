package vn.edu.dbms.bluestock.accounting.application;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

public final class ReconciliationModels {
    private ReconciliationModels() {}

    public record ReconciliationView(String loaiChungTu, String maChungTu,
        BigDecimal giaTriChungTu, BigDecimal giaTriDoiSoat, BigDecimal chenhLech,
        String trangThai, String ghiChu, String maTaiKhoanKeToan,
        OffsetDateTime thoiGian) {}
}
