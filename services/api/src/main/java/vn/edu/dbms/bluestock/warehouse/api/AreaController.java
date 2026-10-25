package vn.edu.dbms.bluestock.warehouse.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
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
import vn.edu.dbms.bluestock.warehouse.application.WarehouseModels.AreaView;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseModels.Page;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseService;

@RestController
@RequestMapping("/api/khu-vuc")
public class AreaController {
    private final WarehouseService service;

    public AreaController(WarehouseService service) {
        this.service = service;
    }

    @GetMapping
    public Page<AreaView> list(@RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size,
        @RequestParam(required = false) String maKho,
        @RequestParam(required = false) String q) {
        return service.areas(page, size, maKho, q);
    }

    @GetMapping("/{maKhuVuc}")
    public AreaView get(@PathVariable String maKhuVuc) {
        return service.area(maKhuVuc);
    }

    @PostMapping
    public ResponseEntity<AreaView> create(@Valid @RequestBody CreateAreaRequest body) {
        AreaView created = service.createArea(
            body.maKhuVuc(), body.maKho(), body.tenKhuVuc(), body.loaiKhuVuc());
        return ResponseEntity.created(URI.create("/api/khu-vuc/" + created.maKhuVuc()))
            .body(created);
    }

    @PutMapping("/{maKhuVuc}")
    public AreaView update(@PathVariable String maKhuVuc, @Valid @RequestBody UpdateAreaRequest body) {
        return service.updateArea(maKhuVuc, body.tenKhuVuc());
    }

    @DeleteMapping("/{maKhuVuc}")
    public ResponseEntity<Void> delete(@PathVariable String maKhuVuc) {
        service.deleteArea(maKhuVuc);
        return ResponseEntity.noContent().build();
    }

    public record CreateAreaRequest(String maKhuVuc,
        @NotBlank String maKho,
        @NotBlank @Size(max = 255) String tenKhuVuc,
        @NotBlank @Pattern(regexp = "Khô|Mát|Đông lạnh") String loaiKhuVuc) {}

    public record UpdateAreaRequest(@NotBlank @Size(max = 255) String tenKhuVuc) {}
}
