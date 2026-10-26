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

    // Draft rows may be incomplete; completion has its own validated AllocationData.
    public record DraftAllocation(String maSanPham, String maViTri, String soLuong,
        String ngaySanXuat, String hanSuDung) {}

    public record LineView(String maSanPham, String tenSanPham, int soLuong,
        BigDecimal donGiaNhap) {}

    public record InboundView(String maPhieuNhap, OffsetDateTime ngayNhap,
        String maNhaCungCap, String tenNhaCungCap, String maNhanVien,
        String trangThai, String ghiChu, OffsetDateTime ngayHoanTat,
        List<LineView> chiTiet, List<DraftAllocation> phanBo) {}

    public record InboundSummary(String maPhieuNhap, OffsetDateTime ngayNhap,
        String maNhaCungCap, String tenNhaCungCap, String maNhanVien,
        String trangThai, String ghiChu, OffsetDateTime ngayHoanTat) {}

    public record InboundPage(List<InboundSummary> items, int page, int size,
        long totalElements, long totalPages) {}

    public record HistoryItem(String maPhieuNhap, OffsetDateTime ngayHoanTat,
        String maNhaCungCap, String maSanPham, String tenSanPham, String maDonViTinh,
        String maLo, LocalDate ngaySanXuat, LocalDate hanSuDung, int soLuongNhap,
        BigDecimal donGiaNhap, BigDecimal giaTriNhap) {}

    public record HistoryPage(List<HistoryItem> items, int page, int size,
        long totalElements, long totalPages) {}

    public record CompletionView(String maPhieuNhap, String trangThai,
        OffsetDateTime ngayHoanTat) {}
}
