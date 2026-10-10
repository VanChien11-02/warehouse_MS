package vn.edu.dbms.bluestock.transfer.application;

import java.time.OffsetDateTime;
import java.util.List;

public final class TransferModels {
    private TransferModels() {}

    public record LineData(String maLo, String maViTriNguon, String maViTriDich, int soLuong) {}

    public record LineView(String maLo, String maSanPham, String tenSanPham,
        String maViTriNguon, String maViTriDich, int soLuong) {}

    public record TransferView(String maPhieuChuyen, OffsetDateTime ngayChuyen,
        String maNhanVien, String trangThai, String ghiChu,
        OffsetDateTime ngayHoanTat, List<LineView> chiTiet) {}

    public record TransferSummary(String maPhieuChuyen, OffsetDateTime ngayChuyen,
        String maNhanVien, String trangThai, String ghiChu, OffsetDateTime ngayHoanTat) {}

    public record TransferPage(List<TransferSummary> items, int page, int size,
        long totalElements, long totalPages) {}

    public record CompletionView(String maPhieuChuyen, String trangThai,
        OffsetDateTime ngayHoanTat) {}
}
