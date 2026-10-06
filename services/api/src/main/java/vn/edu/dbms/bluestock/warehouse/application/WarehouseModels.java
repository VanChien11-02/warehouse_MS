package vn.edu.dbms.bluestock.warehouse.application;

import java.util.List;

public final class WarehouseModels {
    private WarehouseModels() {}

    public record WarehouseView(String maKho, String tenKho, String diaChi) {}

    public record AreaView(String maKhuVuc, String maKho, String tenKho,
        String tenKhuVuc, String loaiKhuVuc) {}

    public record PositionView(String maViTri, String maKhuVuc, String tenKhuVuc,
        String maKho, String tenKho, String tenViTri, int sucChua,
        String loaiViTri, String loaiKhuVuc) {}

    public record Page<T>(List<T> items, int page, int size, long totalElements, long totalPages) {}
}
