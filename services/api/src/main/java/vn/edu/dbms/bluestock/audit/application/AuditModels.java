package vn.edu.dbms.bluestock.audit.application;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;

public final class AuditModels {
    private AuditModels() {}

    public record AuditView(long maLichSu, String maTaiKhoan, OffsetDateTime thoiGian,
        String hanhDong, String tenBang, String maBanGhi,
        String duLieuCu, String duLieuMoi) {}

    public record AuditPage(LocalDate tuNgay, LocalDate denNgay,
        List<AuditView> items, int page, int size, long totalElements, long totalPages) {}
}
