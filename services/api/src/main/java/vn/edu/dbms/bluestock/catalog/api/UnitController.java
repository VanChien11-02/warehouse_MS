package vn.edu.dbms.bluestock.catalog.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.net.URI;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import vn.edu.dbms.bluestock.catalog.application.CatalogReferenceModels.Page;
import vn.edu.dbms.bluestock.catalog.application.CatalogReferenceModels.UnitView;
import vn.edu.dbms.bluestock.catalog.application.CatalogReferenceService;

@RestController
@RequestMapping("/api/don-vi-tinh")
public class UnitController {
    private final CatalogReferenceService service;

    public UnitController(CatalogReferenceService service) {
        this.service = service;
    }

    @GetMapping
    public Page<UnitView> list(@RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size, @RequestParam(required = false) String q) {
        return service.units(page, size, q);
    }

    @GetMapping("/{maDonViTinh}")
    public UnitView get(@PathVariable String maDonViTinh) {
        return service.unit(maDonViTinh);
    }

    @PostMapping
    public ResponseEntity<UnitView> create(@Valid @RequestBody CreateUnitRequest body) {
        UnitView created = service.createUnit(body.maDonViTinh(), body.tenDonViTinh());
        return ResponseEntity.created(URI.create("/api/don-vi-tinh/" + created.maDonViTinh()))
            .body(created);
    }

    @PutMapping("/{maDonViTinh}")
    public UnitView update(@PathVariable String maDonViTinh, @Valid @RequestBody UpdateUnitRequest body) {
        return service.updateUnit(maDonViTinh, body.tenDonViTinh());
    }

    @DeleteMapping("/{maDonViTinh}")
    public ResponseEntity<Void> delete(@PathVariable String maDonViTinh) {
        service.deleteUnit(maDonViTinh);
        return ResponseEntity.noContent().build();
    }

    public record CreateUnitRequest(@NotBlank String maDonViTinh,
        @NotBlank @Size(max = 100) String tenDonViTinh) {}

    public record UpdateUnitRequest(@NotBlank @Size(max = 100) String tenDonViTinh) {}
}
