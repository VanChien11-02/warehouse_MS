package vn.edu.dbms.bluestock.accounting.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import vn.edu.dbms.bluestock.accounting.application.ReconciliationModels.ReconciliationView;
import vn.edu.dbms.bluestock.accounting.application.ReconciliationService;
import vn.edu.dbms.bluestock.auth.infrastructure.AccountPrincipal;

@RestController
@RequestMapping("/api/doi-soat-gia-tri")
public class ReconciliationController {
    private final ReconciliationService service;

    public ReconciliationController(ReconciliationService service) { this.service = service; }

    @GetMapping("/{loaiChungTu}/{maChungTu}")
    public ReconciliationView get(@PathVariable String loaiChungTu,
        @PathVariable String maChungTu) {
        return service.get(loaiChungTu, maChungTu);
    }

    @PostMapping("/{loaiChungTu}/{maChungTu}")
    public ReconciliationView reconcile(@PathVariable String loaiChungTu,
        @PathVariable String maChungTu, @Valid @RequestBody ReconciliationRequest body,
        @AuthenticationPrincipal AccountPrincipal principal) {
        return service.reconcile(loaiChungTu, maChungTu, body.giaTriDoiSoat(),
            body.ghiChu(), principal.maTaiKhoan());
    }

    public record ReconciliationRequest(@NotNull @DecimalMin("0.0000")
        @Digits(integer = 15, fraction = 4) BigDecimal giaTriDoiSoat,
        @Size(max = 1000) String ghiChu) {}
}
