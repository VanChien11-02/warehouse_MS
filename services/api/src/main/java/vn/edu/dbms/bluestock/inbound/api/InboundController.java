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
import org.springframework.format.annotation.DateTimeFormat;
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
import vn.edu.dbms.bluestock.inbound.application.InboundModels.AllocationData;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.CompletionView;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.DraftAllocation;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.InboundView;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.InboundPage;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.LineData;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.HistoryPage;
import vn.edu.dbms.bluestock.inbound.application.InboundService;

@RestController
@RequestMapping("/api/phieu-nhap")
public class InboundController {
    private final InboundService service;

    public InboundController(InboundService service) {
        this.service = service;
    }

    @GetMapping
    public InboundPage list(@RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size,
        @RequestParam(required = false) String trangThai,
        @RequestParam(required = false) String maNhaCungCap) {
        return service.list(page, size, trangThai, maNhaCungCap);
    }

    @GetMapping("/{maPhieuNhap}")
    public InboundView get(@PathVariable String maPhieuNhap) {
        return service.get(maPhieuNhap);
    }

    @GetMapping("/lich-su")
    public HistoryPage history(
        @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size,
        @RequestParam(required = false) String maPhieuNhap,
        @RequestParam(required = false) String maSanPham,
        @RequestParam(required = false) String maNhaCungCap,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate tuNgay,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate denNgay) {
        return service.history(page, size, maPhieuNhap, maSanPham, maNhaCungCap, tuNgay, denNgay);
    }

    @PostMapping
    public ResponseEntity<InboundView> create(
        @Valid @RequestBody CreateInboundRequest body,
        @AuthenticationPrincipal AccountPrincipal principal
    ) {
        InboundView created = service.create(body.maNhaCungCap(), principal.maNhanVien(),
            body.ghiChu(), body.chiTiet().stream().map(LineRequest::data).toList(),
            body.phanBo() == null ? null : body.phanBo().stream().map(DraftAllocationRequest::data).toList());
        return ResponseEntity.created(URI.create("/api/phieu-nhap/" + created.maPhieuNhap()))
            .body(created);
    }

    @PutMapping("/{maPhieuNhap}")
    public InboundView update(@PathVariable String maPhieuNhap,
        @Valid @RequestBody CreateInboundRequest body) {
        return service.update(maPhieuNhap, body.maNhaCungCap(), body.ghiChu(),
            body.chiTiet().stream().map(LineRequest::data).toList(),
            body.phanBo() == null ? null : body.phanBo().stream().map(DraftAllocationRequest::data).toList());
    }

    @PostMapping("/{maPhieuNhap}/huy")
    public InboundView cancel(@PathVariable String maPhieuNhap,
        @AuthenticationPrincipal AccountPrincipal principal) {
        return service.cancel(maPhieuNhap, principal.maTaiKhoan());
    }

    @PostMapping("/{maPhieuNhap}/hoan-tat")
    public CompletionView complete(@PathVariable String maPhieuNhap,
        @Valid @RequestBody CompletionRequest body,
        @AuthenticationPrincipal AccountPrincipal principal) {
        return service.complete(maPhieuNhap, body.phanBo().stream()
            .map(AllocationRequest::data).toList(), principal.maTaiKhoan());
    }

    public record CreateInboundRequest(@NotBlank String maNhaCungCap,
        @Size(max = 1000) String ghiChu,
        @NotEmpty List<@NotNull @Valid LineRequest> chiTiet,
        @Size(max = 100) List<@NotNull @Valid DraftAllocationRequest> phanBo) {}

    public record DraftAllocationRequest(@Size(max = 6) String maSanPham,
        @Size(max = 6) String maViTri, @Size(max = 12) String soLuong,
        @Size(max = 10) String ngaySanXuat, @Size(max = 10) String hanSuDung) {
        DraftAllocation data() {
            return new DraftAllocation(maSanPham, maViTri, soLuong, ngaySanXuat, hanSuDung);
        }
    }

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
