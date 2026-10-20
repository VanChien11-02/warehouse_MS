package vn.edu.dbms.bluestock.transfer.api;

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
import vn.edu.dbms.bluestock.transfer.application.TransferModels.CompletionView;
import vn.edu.dbms.bluestock.transfer.application.TransferModels.LineData;
import vn.edu.dbms.bluestock.transfer.application.TransferModels.TransferView;
import vn.edu.dbms.bluestock.transfer.application.TransferModels.TransferPage;
import vn.edu.dbms.bluestock.transfer.application.TransferService;

@RestController
@RequestMapping("/api/phieu-chuyen")
public class TransferController {
    private final TransferService service;

    public TransferController(TransferService service) {
        this.service = service;
    }

    @GetMapping
    public TransferPage list(@RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size,
        @RequestParam(required = false) String trangThai) {
        return service.list(page, size, trangThai);
    }

    @GetMapping("/{maPhieuChuyen}")
    public TransferView get(@PathVariable String maPhieuChuyen) {
        return service.get(maPhieuChuyen);
    }

    @PostMapping
    public ResponseEntity<TransferView> create(@Valid @RequestBody CreateTransferRequest body,
        @AuthenticationPrincipal AccountPrincipal principal) {
        TransferView created = service.create(principal.maNhanVien(), body.ghiChu(),
            body.chiTiet().stream().map(LineRequest::data).toList());
        return ResponseEntity.created(URI.create("/api/phieu-chuyen/" + created.maPhieuChuyen()))
            .body(created);
    }

    @PutMapping("/{maPhieuChuyen}")
    public TransferView update(@PathVariable String maPhieuChuyen,
        @Valid @RequestBody CreateTransferRequest body) {
        return service.update(maPhieuChuyen, body.ghiChu(),
            body.chiTiet().stream().map(LineRequest::data).toList());
    }

    @PostMapping("/{maPhieuChuyen}/huy")
    public TransferView cancel(@PathVariable String maPhieuChuyen,
        @AuthenticationPrincipal AccountPrincipal principal) {
        return service.cancel(maPhieuChuyen, principal.maTaiKhoan());
    }

    @PostMapping("/{maPhieuChuyen}/hoan-tat")
    public CompletionView complete(@PathVariable String maPhieuChuyen,
        @AuthenticationPrincipal AccountPrincipal principal) {
        return service.complete(maPhieuChuyen, principal.maTaiKhoan());
    }

    public record CreateTransferRequest(@Size(max = 1000) String ghiChu,
        @NotEmpty List<@NotNull @Valid LineRequest> chiTiet) {}

    public record LineRequest(@NotBlank String maLo,
        @NotBlank String maViTriNguon, @NotBlank String maViTriDich,
        @Positive int soLuong) {
        LineData data() {
            return new LineData(maLo, maViTriNguon, maViTriDich, soLuong);
        }
    }
}
