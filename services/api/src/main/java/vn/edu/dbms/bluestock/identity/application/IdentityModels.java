package vn.edu.dbms.bluestock.identity.application;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public final class IdentityModels {
    private IdentityModels() {}

    public record EmployeeData(String tenNhanVien, String soDienThoai,
        String gioiTinh, LocalDate ngaySinh, String diaChi, BigDecimal luong,
        LocalDate ngayVaoLam, boolean dangLamViec) {}

    public record EmployeeView(String maNhanVien, String tenNhanVien,
        String soDienThoai, String gioiTinh, LocalDate ngaySinh, String diaChi,
        BigDecimal luong, LocalDate ngayVaoLam, boolean dangLamViec) {}

    public record EmployeePage(List<EmployeeView> items, int page, int size,
        long totalElements, long totalPages) {}

    public record AccountView(String maTaiKhoan, String maNhanVien,
        String tenNhanVien, String tenTaiKhoan, String role, boolean trangThai) {}

    public record AccountPage(List<AccountView> items, int page, int size,
        long totalElements, long totalPages) {}
}
