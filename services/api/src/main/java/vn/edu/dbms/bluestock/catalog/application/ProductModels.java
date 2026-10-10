package vn.edu.dbms.bluestock.catalog.application;

import java.math.BigDecimal;
import java.util.List;

public final class ProductModels {
    private ProductModels() {}

    public record ProductData(
        String tenSanPham,
        BigDecimal giaNhapMacDinh,
        BigDecimal giaBanMacDinh
    ) {}

    public record ProductView(
        String maSanPham,
        String tenSanPham,
        String maLoai,
        String tenLoai,
        String maDonViTinh,
        String tenDonViTinh,
        BigDecimal giaNhapMacDinh,
        BigDecimal giaBanMacDinh
    ) {}

    public record ProductPage(
        List<ProductView> items,
        int page,
        int size,
        long totalElements,
        long totalPages
    ) {}
}
