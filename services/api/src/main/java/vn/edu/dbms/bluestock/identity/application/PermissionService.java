package vn.edu.dbms.bluestock.identity.application;

import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class PermissionService {
    public List<RolePermissions> list() {
        return List.of(
            role("ADMIN", "Quản trị viên"),
            role("QLKHO", "Quản lý kho"),
            role("NVKHO", "Nhân viên kho"),
            role("KETOAN", "Kế toán")
        );
    }

    private RolePermissions role(String code, String name) {
        boolean admin = code.equals("ADMIN");
        boolean manager = code.equals("QLKHO");
        boolean staff = code.equals("NVKHO");
        boolean accountant = code.equals("KETOAN");
        boolean warehouseRead = !admin;
        return new RolePermissions(code, name, List.of(
            new ModulePermission("identity", "Nhân viên, tài khoản và gán vai trò", admin, admin, admin, false, false),
            new ModulePermission("catalog", "Sản phẩm, loại và đơn vị tính", warehouseRead, manager, manager, manager, false),
            new ModulePermission("warehouse", "Kho, khu vực và vị trí", warehouseRead, manager, manager, manager, false),
            new ModulePermission("partner", "Đối tác và liên kết sản phẩm", warehouseRead, manager, manager, manager, false),
            new ModulePermission("inbound", "Phiếu nhập kho", warehouseRead, manager || staff, manager || staff, manager || staff, manager),
            new ModulePermission("outbound", "Phiếu xuất kho", warehouseRead, manager || staff, manager || staff, manager || staff, manager),
            new ModulePermission("transfer", "Phiếu chuyển kho", manager || accountant, manager, manager, manager, manager),
            new ModulePermission("count", "Phiếu kiểm kê", manager || accountant, manager, manager, manager, manager),
            new ModulePermission("return", "Phiếu trả hàng", manager || accountant, manager, manager, manager, manager),
            new ModulePermission("inventory", "Tra cứu tồn kho", warehouseRead, false, false, false, false),
            new ModulePermission("reporting", "Nhập–xuất–tồn và chênh lệch kiểm kê", manager || accountant, false, false, false, false),
            new ModulePermission("expiry", "Lô sắp hết hạn", manager, false, false, false, false),
            new ModulePermission("reconciliation", "Đối soát giá trị phiếu nhập/xuất", manager || accountant,
                accountant, false, false, false),
            new ModulePermission("audit", "Nhật ký thao tác", false, false, false, false, false),
            new ModulePermission("inbound-history", "Lịch sử nhập kho theo lô", manager || accountant, false, false, false, false)
        ));
    }

    public record RolePermissions(String role, String tenVaiTro, List<ModulePermission> permissions) {}

    public record ModulePermission(String module, String tenChucNang, boolean xem, boolean tao,
        boolean sua, boolean xoaHoacHuy, boolean hoanTat) {}
}
