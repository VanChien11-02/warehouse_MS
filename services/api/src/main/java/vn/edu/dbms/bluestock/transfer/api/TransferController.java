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
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import vn.edu.dbms.bluestock.auth.infrastructure.AccountPrincipal;
import vn.edu.dbms.bluestock.transfer.application.TransferModels.CompletionView;
import vn.edu.dbms.bluestock.transfer.application.TransferModels.LineData;
import vn.edu.dbms.bluestock.transfer.application.TransferModels.TransferView;
import vn.edu.dbms.bluestock.transfer.application.TransferService;

@RestController
@RequestMapping("/api/phieu-chuyen")
public class TransferController {
    private final TransferService service;

    public TransferController(TransferService service) {
        this.service = service;
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

    @PostMapping("/{maPhieuChuyen}/hoan-tat")
    public CompletionView complete(@PathVariable String maPhieuChuyen) {
        return service.complete(maPhieuChuyen);
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
