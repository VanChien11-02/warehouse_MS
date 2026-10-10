package vn.edu.dbms.bluestock.count.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.net.URI;
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
import vn.edu.dbms.bluestock.count.application.CountModels.CompletionView;
import vn.edu.dbms.bluestock.count.application.CountModels.CountPage;
import vn.edu.dbms.bluestock.count.application.CountModels.CountView;
import vn.edu.dbms.bluestock.count.application.CountService;

@RestController
@RequestMapping("/api/phieu-kiem-ke")
public class CountController {
    private final CountService service;

    public CountController(CountService service) {
        this.service = service;
    }

    @GetMapping
    public CountPage list(@RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size,
        @RequestParam(required = false) String trangThai,
        @RequestParam(required = false) String maViTri) {
        return service.list(page, size, trangThai, maViTri);
    }

    @GetMapping("/{maPhieuKiemKe}")
    public CountView get(@PathVariable String maPhieuKiemKe) {
        return service.get(maPhieuKiemKe);
    }

    @PostMapping
    public ResponseEntity<CountView> create(@Valid @RequestBody CreateCountRequest body,
        @AuthenticationPrincipal AccountPrincipal principal) {
        CountView created = service.create(principal.maNhanVien(), body.maViTri(), body.ghiChu());
        return ResponseEntity.created(URI.create("/api/phieu-kiem-ke/" + created.maPhieuKiemKe()))
            .body(created);
    }

    @PutMapping("/{maPhieuKiemKe}/chi-tiet/{maLo}")
    public CountView setActual(@PathVariable String maPhieuKiemKe, @PathVariable String maLo,
        @Valid @RequestBody SetActualRequest body) {
        return service.setActual(maPhieuKiemKe, maLo,
            body.soLuongThucTe(), body.lyDoChenhLech());
    }

    @PostMapping("/{maPhieuKiemKe}/huy")
    public CountView cancel(@PathVariable String maPhieuKiemKe) {
        return service.cancel(maPhieuKiemKe);
    }

    @PostMapping("/{maPhieuKiemKe}/hoan-tat")
    public CompletionView complete(@PathVariable String maPhieuKiemKe) {
        return service.complete(maPhieuKiemKe);
    }

    public record CreateCountRequest(@NotBlank String maViTri,
        @Size(max = 1000) String ghiChu) {}

    public record SetActualRequest(@NotNull @Min(0) Integer soLuongThucTe,
        @Size(max = 500) String lyDoChenhLech) {}
}
