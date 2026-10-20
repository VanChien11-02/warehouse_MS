package vn.edu.dbms.bluestock.returning.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.net.URI;
import java.util.List;
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
import vn.edu.dbms.bluestock.auth.infrastructure.AccountPrincipal;
import vn.edu.dbms.bluestock.returning.application.ReturnModels.CompletionView;
import vn.edu.dbms.bluestock.returning.application.ReturnModels.LineData;
import vn.edu.dbms.bluestock.returning.application.ReturnModels.ReturnPage;
import vn.edu.dbms.bluestock.returning.application.ReturnModels.ReturnView;
import vn.edu.dbms.bluestock.returning.application.ReturnService;

@RestController
@RequestMapping("/api/phieu-tra-hang")
public class ReturnController {
    private final ReturnService service;

    public ReturnController(ReturnService service) {
        this.service = service;
    }

    @GetMapping
    public ReturnPage list(@RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size,
        @RequestParam(required = false) String trangThai,
        @RequestParam(required = false) String maPhieuXuat) {
        return service.list(page, size, trangThai, maPhieuXuat);
    }

    @GetMapping("/{maPhieuTraHang}")
    public ReturnView get(@PathVariable String maPhieuTraHang) {
        return service.get(maPhieuTraHang);
    }

    @PostMapping
    public ResponseEntity<ReturnView> create(@Valid @RequestBody CreateReturnRequest body,
        @AuthenticationPrincipal AccountPrincipal principal) {
        ReturnView created = service.create(principal.maNhanVien(), body.maPhieuXuat(),
            body.ghiChu(), body.chiTiet().stream().map(LineRequest::data).toList());
        return ResponseEntity.created(URI.create("/api/phieu-tra-hang/" + created.maPhieuTraHang()))
            .body(created);
    }

    @PutMapping("/{maPhieuTraHang}")
    public ReturnView update(@PathVariable String maPhieuTraHang,
        @Valid @RequestBody UpdateReturnRequest body) {
        return service.update(maPhieuTraHang, body.ghiChu(),
            body.chiTiet().stream().map(LineRequest::data).toList());
    }

    @PostMapping("/{maPhieuTraHang}/huy")
    public ReturnView cancel(@PathVariable String maPhieuTraHang,
        @AuthenticationPrincipal AccountPrincipal principal) {
        return service.cancel(maPhieuTraHang, principal.maTaiKhoan());
    }

    @PostMapping("/{maPhieuTraHang}/hoan-tat")
    public CompletionView complete(@PathVariable String maPhieuTraHang,
        @AuthenticationPrincipal AccountPrincipal principal) {
        return service.complete(maPhieuTraHang, principal.maTaiKhoan());
    }

    public record CreateReturnRequest(@NotBlank String maPhieuXuat,
        @Size(max = 1000) String ghiChu,
        @NotEmpty List<@NotNull @Valid LineRequest> chiTiet) {}

    public record UpdateReturnRequest(@Size(max = 1000) String ghiChu,
        @NotEmpty List<@NotNull @Valid LineRequest> chiTiet) {}

    public record LineRequest(@NotBlank String maLo, @NotBlank String maViTri,
        @Positive int soLuong, @NotBlank String tinhTrang) {
        LineData data() {
            return new LineData(maLo, maViTri, soLuong, tinhTrang);
        }
    }
}
