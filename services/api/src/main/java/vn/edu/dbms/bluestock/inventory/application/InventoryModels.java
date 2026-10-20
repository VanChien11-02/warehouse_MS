package vn.edu.dbms.bluestock.inventory.application;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;

public final class InventoryModels {
    private InventoryModels() {}

    public record StockView(String maKho, String tenKho, String maKhuVuc,
        String tenKhuVuc, String maViTri, String tenViTri, String loaiViTri,
        String maLo, String maSanPham, String tenSanPham, String maDonViTinh,
        int soLuongTon, LocalDate ngaySanXuat, LocalDate hanSuDung,
        String maPhieuNhap, OffsetDateTime ngayHoanTat, BigDecimal donGiaNhap,
        BigDecimal giaTriTon, boolean khaDung) {}

    public record StockPage(List<StockView> items, int page, int size,
        long totalElements, long totalPages) {}

    public record StockFilter(String maKho, String maViTri, String maSanPham,
        String maLo, LocalDate hanSuDungTruoc, boolean chiKhaDung) {}
}
