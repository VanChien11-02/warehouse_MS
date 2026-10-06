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
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import vn.edu.dbms.bluestock.auth.infrastructure.AccountPrincipal;
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.CompletionView;
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.LineData;
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.OutboundView;
import vn.edu.dbms.bluestock.outbound.application.OutboundService;

@RestController
@RequestMapping("/api/phieu-xuat")
public class OutboundController {
    private final OutboundService service;

    public OutboundController(OutboundService service) {
        this.service = service;
    }

    @GetMapping("/{maPhieuXuat}")
    public OutboundView get(@PathVariable String maPhieuXuat) {
        return service.get(maPhieuXuat);
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

    @PostMapping("/{maPhieuXuat}/hoan-tat")
    public CompletionView complete(@PathVariable String maPhieuXuat) {
        return service.complete(maPhieuXuat);
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
