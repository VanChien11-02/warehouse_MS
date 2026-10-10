package vn.edu.dbms.bluestock.catalog.application;

import java.util.List;

public final class CatalogReferenceModels {
    private CatalogReferenceModels() {}

    public record CategoryView(String maLoai, String tenLoai, String moTa, String yeuCauBaoQuan) {}

    public record UnitView(String maDonViTinh, String tenDonViTinh) {}

    public record Page<T>(List<T> items, int page, int size, long totalElements, long totalPages) {}
}
