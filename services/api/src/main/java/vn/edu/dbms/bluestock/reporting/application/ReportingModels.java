package vn.edu.dbms.bluestock.reporting.application;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public final class ReportingModels {
    private ReportingModels() {}

    public record MovementReportRow(String maKho, String tenKho, String maSanPham,
        String tenSanPham, String maDonViTinh, long soLuongDauKy, long soLuongNhap,
        long soLuongXuat, long soLuongDieuChinh, long soLuongCuoiKy,
        BigDecimal giaTriDauKy, BigDecimal giaTriNhap, BigDecimal giaTriXuat,
        BigDecimal giaTriDieuChinh, BigDecimal giaTriCuoiKy) {}

    public record MovementReportPage(LocalDate tuNgay, LocalDate denNgay,
        List<MovementReportRow> items, int page, int size,
        long totalElements, long totalPages) {}
}
