package vn.edu.dbms.bluestock.identity.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.net.URI;
import java.time.LocalDate;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import vn.edu.dbms.bluestock.identity.application.IdentityModels.EmployeeData;
import vn.edu.dbms.bluestock.identity.application.IdentityModels.EmployeePage;
import vn.edu.dbms.bluestock.identity.application.IdentityModels.EmployeeView;
import vn.edu.dbms.bluestock.identity.application.IdentityService;
import vn.edu.dbms.bluestock.auth.infrastructure.AccountPrincipal;

@RestController
@RequestMapping("/api/nhan-vien")
public class EmployeeController {
    private final IdentityService service;

    public EmployeeController(IdentityService service) {
        this.service = service;
    }

    @GetMapping
    public EmployeePage list(@RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size) {
        return service.listEmployees(page, size);
    }

    @GetMapping("/{maNhanVien}")
    public EmployeeView get(@PathVariable String maNhanVien) {
        return service.getEmployee(maNhanVien);
    }

    @PostMapping
    public ResponseEntity<EmployeeView> create(@Valid @RequestBody CreateEmployeeRequest body,
        @AuthenticationPrincipal AccountPrincipal principal) {
        EmployeeView created = service.createEmployee(body.maNhanVien(), body.data(),
            principal.maTaiKhoan());
        return ResponseEntity.created(URI.create("/api/nhan-vien/" + created.maNhanVien()))
            .body(created);
    }

    @PutMapping("/{maNhanVien}")
    public EmployeeView update(@PathVariable String maNhanVien,
        @Valid @RequestBody UpdateEmployeeRequest body,
        @AuthenticationPrincipal AccountPrincipal principal) {
        return service.updateEmployee(maNhanVien, body.data(), principal.maNhanVien(),
            principal.maTaiKhoan());
    }

    public record CreateEmployeeRequest(@NotBlank String maNhanVien,
        @NotBlank @Size(max = 255) String tenNhanVien,
        @Size(max = 20) String soDienThoai, String gioiTinh,
        LocalDate ngaySinh, @Size(max = 500) String diaChi,
        @DecimalMin("0.0") @Digits(integer = 15, fraction = 4) BigDecimal luong,
        @NotNull LocalDate ngayVaoLam) {
        EmployeeData data() {
            return new EmployeeData(tenNhanVien, soDienThoai, gioiTinh,
                ngaySinh, diaChi, luong, ngayVaoLam, true);
        }
    }

    public record UpdateEmployeeRequest(@NotBlank @Size(max = 255) String tenNhanVien,
        @Size(max = 20) String soDienThoai, String gioiTinh,
        LocalDate ngaySinh, @Size(max = 500) String diaChi,
        @DecimalMin("0.0") @Digits(integer = 15, fraction = 4) BigDecimal luong,
        @NotNull LocalDate ngayVaoLam, @NotNull Boolean dangLamViec) {
        EmployeeData data() {
            return new EmployeeData(tenNhanVien, soDienThoai, gioiTinh,
                ngaySinh, diaChi, luong, ngayVaoLam, dangLamViec);
        }
    }
}
