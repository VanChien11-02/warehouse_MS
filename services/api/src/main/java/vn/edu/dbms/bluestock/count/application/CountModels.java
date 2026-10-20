package vn.edu.dbms.bluestock.count.application;

import java.time.OffsetDateTime;
import java.util.List;

public final class CountModels {
    private CountModels() {}

    public record LineView(String maLo, String maSanPham, String tenSanPham,
        int soLuongHeThong, Integer soLuongThucTe, String lyDoChenhLech) {}

    public record CountView(String maPhieuKiemKe, OffsetDateTime ngayKiemKe,
        String maNhanVien, String maViTri, String trangThai, String ghiChu,
        OffsetDateTime ngayHoanTat, List<LineView> chiTiet) {}

    public record CountSummary(String maPhieuKiemKe, OffsetDateTime ngayKiemKe,
        String maNhanVien, String maViTri, String trangThai, String ghiChu,
        OffsetDateTime ngayHoanTat) {}

    public record CountPage(List<CountSummary> items, int page, int size,
        long totalElements, long totalPages) {}

    public record CompletionView(String maPhieuKiemKe, String trangThai,
        OffsetDateTime ngayHoanTat) {}
}
