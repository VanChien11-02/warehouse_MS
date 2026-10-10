package vn.edu.dbms.bluestock.returning.application;

import java.time.OffsetDateTime;
import java.util.List;

public final class ReturnModels {
    private ReturnModels() {}

    public record LineData(String maLo, String maViTri, int soLuong, String tinhTrang) {}

    public record LineView(String maLo, String maSanPham, String tenSanPham,
        String maViTri, int soLuong, String tinhTrang) {}

    public record ReturnView(String maPhieuTraHang, OffsetDateTime ngayTra,
        String maPhieuXuat, String maNhanVien, String trangThai, String ghiChu,
        OffsetDateTime ngayHoanTat, List<LineView> chiTiet) {}

    public record ReturnSummary(String maPhieuTraHang, OffsetDateTime ngayTra,
        String maPhieuXuat, String maNhanVien, String trangThai, String ghiChu,
        OffsetDateTime ngayHoanTat) {}

    public record ReturnPage(List<ReturnSummary> items, int page, int size,
        long totalElements, long totalPages) {}

    public record CompletionView(String maPhieuTraHang, String trangThai,
        OffsetDateTime ngayHoanTat) {}
}
