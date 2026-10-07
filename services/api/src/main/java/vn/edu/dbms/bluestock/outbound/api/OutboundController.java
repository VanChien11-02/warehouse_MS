package vn.edu.dbms.bluestock.outbound.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
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
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.CompletionView;
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.FefoSuggestion;
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.LineData;
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.OutboundView;
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.OutboundPage;
import vn.edu.dbms.bluestock.outbound.application.OutboundService;

@RestController
@RequestMapping("/api/phieu-xuat")
public class OutboundController {
    private final OutboundService service;

    public OutboundController(OutboundService service) {
        this.service = service;
    }

    @GetMapping
    public OutboundPage list(@RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size,
        @RequestParam(required = false) String trangThai,
        @RequestParam(required = false) String maDoiTacNhanHang) {
        return service.list(page, size, trangThai, maDoiTacNhanHang);
    }

    @GetMapping("/{maPhieuXuat}")
    public OutboundView get(@PathVariable String maPhieuXuat) {
        return service.get(maPhieuXuat);
    }

    @GetMapping("/{maPhieuXuat}/goi-y-fefo")
    public FefoSuggestion suggest(@PathVariable String maPhieuXuat,
        @RequestParam String maSanPham, @RequestParam int soLuong,
        @RequestParam(required = false) String maKho) {
        return service.suggest(maPhieuXuat, maSanPham, soLuong, maKho);
    }

    @PostMapping
    public ResponseEntity<OutboundView> create(
        @Valid @RequestBody CreateOutboundRequest body,
        @AuthenticationPrincipal AccountPrincipal principal
    ) {
        OutboundView created = service.create(body.maDoiTacNhanHang(), principal.maNhanVien(),
            body.ghiChu(), body.chiTiet().stream().map(LineRequest::data).toList());
        return ResponseEntity.created(URI.create("/api/phieu-xuat/" + created.maPhieuXuat()))
            .body(created);
    }

    @PutMapping("/{maPhieuXuat}")
    public OutboundView update(@PathVariable String maPhieuXuat,
        @Valid @RequestBody CreateOutboundRequest body) {
        return service.update(maPhieuXuat, body.maDoiTacNhanHang(), body.ghiChu(),
            body.chiTiet().stream().map(LineRequest::data).toList());
    }

    @PostMapping("/{maPhieuXuat}/huy")
    public OutboundView cancel(@PathVariable String maPhieuXuat,
        @AuthenticationPrincipal AccountPrincipal principal) {
        return service.cancel(maPhieuXuat, principal.maTaiKhoan());
    }

    @PostMapping("/{maPhieuXuat}/hoan-tat")
    public CompletionView complete(@PathVariable String maPhieuXuat,
        @AuthenticationPrincipal AccountPrincipal principal) {
        return service.complete(maPhieuXuat, principal.maTaiKhoan());
    }

    public record CreateOutboundRequest(@NotBlank String maDoiTacNhanHang,
        @Size(max = 1000) String ghiChu,
        @NotEmpty List<@NotNull @Valid LineRequest> chiTiet) {}

    public record LineRequest(@NotBlank String maLo,
        @NotBlank String maViTri,
        @Positive int soLuong,
        @NotNull @DecimalMin("0.0000") @Digits(integer = 15, fraction = 4)
            BigDecimal donGiaXuat) {
        LineData data() { return new LineData(maLo, maViTri, soLuong, donGiaXuat); }
    }
}
