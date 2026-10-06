package vn.edu.dbms.bluestock.outbound.application;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;

public final class OutboundModels {
    private OutboundModels() {}

    public record LineData(String maLo, String maViTri, int soLuong, BigDecimal donGiaXuat) {}

    public record LineView(String maLo, String maViTri, String maSanPham,
        String tenSanPham, LocalDate hanSuDung, int soLuong, BigDecimal donGiaXuat) {}

    public record OutboundView(String maPhieuXuat, OffsetDateTime ngayXuat,
        String maDoiTacNhanHang, String tenDoiTac, String maNhanVien,
        String trangThai, String ghiChu, OffsetDateTime ngayHoanTat,
        List<LineView> chiTiet) {}

    public record OutboundSummary(String maPhieuXuat, OffsetDateTime ngayXuat,
        String maDoiTacNhanHang, String tenDoiTac, String maNhanVien,
        String trangThai, String ghiChu, OffsetDateTime ngayHoanTat) {}

    public record OutboundPage(List<OutboundSummary> items, int page, int size,
        long totalElements, long totalPages) {}

    public record CompletionView(String maPhieuXuat, String trangThai,
        OffsetDateTime ngayHoanTat) {}

    public record FefoAllocation(String maLo, String maViTri, int soLuong,
        LocalDate hanSuDung) {}

    public record FefoSuggestion(String maPhieuXuat, String maSanPham,
        int soLuongYeuCau, int soLuongThieu, List<FefoAllocation> phanBo) {}
}
