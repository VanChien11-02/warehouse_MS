package vn.edu.dbms.bluestock.inbound.application;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;

public final class InboundModels {
    private InboundModels() {}

    public record LineData(String maSanPham, int soLuong, BigDecimal donGiaNhap) {}

    public record AllocationData(String maSanPham, String maViTri, int soLuong,
        LocalDate ngaySanXuat, LocalDate hanSuDung) {}

    public record LineView(String maSanPham, String tenSanPham, int soLuong,
        BigDecimal donGiaNhap) {}

    public record InboundView(String maPhieuNhap, OffsetDateTime ngayNhap,
        String maNhaCungCap, String tenNhaCungCap, String maNhanVien,
        String trangThai, String ghiChu, OffsetDateTime ngayHoanTat,
        List<LineView> chiTiet) {}

    public record InboundSummary(String maPhieuNhap, OffsetDateTime ngayNhap,
        String maNhaCungCap, String tenNhaCungCap, String maNhanVien,
        String trangThai, String ghiChu, OffsetDateTime ngayHoanTat) {}

    public record InboundPage(List<InboundSummary> items, int page, int size,
        long totalElements, long totalPages) {}

    public record CompletionView(String maPhieuNhap, String trangThai,
        OffsetDateTime ngayHoanTat) {}
}
