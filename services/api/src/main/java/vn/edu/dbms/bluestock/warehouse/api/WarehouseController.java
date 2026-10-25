package vn.edu.dbms.bluestock.warehouse.api;

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
import vn.edu.dbms.bluestock.warehouse.application.WarehouseModels.Page;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseModels.WarehouseView;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseService;

@RestController
@RequestMapping("/api/kho")
public class WarehouseController {
    private final WarehouseService service;

    public WarehouseController(WarehouseService service) {
        this.service = service;
    }

    @GetMapping
    public Page<WarehouseView> list(@RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size, @RequestParam(required = false) String q) {
        return service.warehouses(page, size, q);
    }

    @GetMapping("/{maKho}")
    public WarehouseView get(@PathVariable String maKho) {
        return service.warehouse(maKho);
    }

    @PostMapping
    public ResponseEntity<WarehouseView> create(@Valid @RequestBody CreateWarehouseRequest body) {
        WarehouseView created = service.createWarehouse(body.maKho(), body.tenKho(), body.diaChi());
        return ResponseEntity.created(URI.create("/api/kho/" + created.maKho())).body(created);
    }

    @PutMapping("/{maKho}")
    public WarehouseView update(@PathVariable String maKho, @Valid @RequestBody UpdateWarehouseRequest body) {
        return service.updateWarehouse(maKho, body.tenKho(), body.diaChi());
    }

    @DeleteMapping("/{maKho}")
    public ResponseEntity<Void> delete(@PathVariable String maKho) {
        service.deleteWarehouse(maKho);
        return ResponseEntity.noContent().build();
    }

    public record CreateWarehouseRequest(String maKho,
        @NotBlank @Size(max = 255) String tenKho, @Size(max = 255) String diaChi) {}

    public record UpdateWarehouseRequest(@NotBlank @Size(max = 255) String tenKho,
        @Size(max = 255) String diaChi) {}
}
