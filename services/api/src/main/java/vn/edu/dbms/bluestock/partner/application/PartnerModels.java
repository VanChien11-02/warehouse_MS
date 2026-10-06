package vn.edu.dbms.bluestock.partner.application;

import java.util.List;

public final class PartnerModels {
    private PartnerModels() {}

    public record SupplierView(String maNhaCungCap, String tenNhaCungCap,
        String diaChi, String soDienThoai, String email) {}

    public record RecipientView(String maDoiTacNhanHang, String tenDoiTac,
        String loaiDoiTac, String diaChi, String soDienThoai, String email) {}

    public record Page<T>(List<T> items, int page, int size, long totalElements, long totalPages) {}
}
