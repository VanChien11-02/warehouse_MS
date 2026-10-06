package vn.edu.dbms.bluestock.inbound.api;

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
import java.time.LocalDate;
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
import vn.edu.dbms.bluestock.inbound.application.InboundModels.AllocationData;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.CompletionView;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.InboundView;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.LineData;
import vn.edu.dbms.bluestock.inbound.application.InboundService;

@RestController
@RequestMapping("/api/phieu-nhap")
public class InboundController {
    private final InboundService service;

    public InboundController(InboundService service) {
        this.service = service;
    }

    @GetMapping("/{maPhieuNhap}")
    public InboundView get(@PathVariable String maPhieuNhap) {
        return service.get(maPhieuNhap);
    }

    @PostMapping
    public ResponseEntity<InboundView> create(
        @Valid @RequestBody CreateInboundRequest body,
        @AuthenticationPrincipal AccountPrincipal principal
    ) {
        InboundView created = service.create(body.maNhaCungCap(), principal.maNhanVien(),
            body.ghiChu(), body.chiTiet().stream().map(LineRequest::data).toList());
        return ResponseEntity.created(URI.create("/api/phieu-nhap/" + created.maPhieuNhap()))
            .body(created);
    }

    @PostMapping("/{maPhieuNhap}/hoan-tat")
    public CompletionView complete(@PathVariable String maPhieuNhap,
        @Valid @RequestBody CompletionRequest body) {
        return service.complete(maPhieuNhap, body.phanBo().stream()
            .map(AllocationRequest::data).toList());
    }

    public record CreateInboundRequest(@NotBlank String maNhaCungCap,
        @Size(max = 1000) String ghiChu,
        @NotEmpty List<@NotNull @Valid LineRequest> chiTiet) {}

    public record LineRequest(@NotBlank String maSanPham,
        @Positive int soLuong,
        @NotNull @DecimalMin("0.0000") @Digits(integer = 15, fraction = 4)
            BigDecimal donGiaNhap) {
        LineData data() { return new LineData(maSanPham, soLuong, donGiaNhap); }
    }

    public record CompletionRequest(@NotEmpty List<@NotNull @Valid AllocationRequest> phanBo) {}

    public record AllocationRequest(@NotBlank String maSanPham,
        @NotBlank String maViTri,
        @Positive int soLuong,
        LocalDate ngaySanXuat,
        LocalDate hanSuDung) {
        AllocationData data() {
            return new AllocationData(maSanPham, maViTri, soLuong, ngaySanXuat, hanSuDung);
        }
    }
}
