package vn.edu.dbms.bluestock.warehouse.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
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
import vn.edu.dbms.bluestock.warehouse.application.WarehouseModels.Page;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseModels.PositionView;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseService;

@RestController
@RequestMapping("/api/vi-tri")
public class PositionController {
    private final WarehouseService service;

    public PositionController(WarehouseService service) {
        this.service = service;
    }

    @GetMapping
    public Page<PositionView> list(@RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size,
        @RequestParam(required = false) String maKho,
        @RequestParam(required = false) String maKhuVuc,
        @RequestParam(required = false) String q) {
        return service.positions(page, size, maKho, maKhuVuc, q);
    }

    @GetMapping("/{maViTri}")
    public PositionView get(@PathVariable String maViTri) {
        return service.position(maViTri);
    }

    @PostMapping
    public ResponseEntity<PositionView> create(@Valid @RequestBody CreatePositionRequest body) {
        PositionView created = service.createPosition(body.maViTri(), body.maKhuVuc(),
            body.tenViTri(), body.sucChua(), body.loaiViTri());
        return ResponseEntity.created(URI.create("/api/vi-tri/" + created.maViTri()))
            .body(created);
    }

    @PutMapping("/{maViTri}")
    public PositionView update(@PathVariable String maViTri, @Valid @RequestBody UpdatePositionRequest body) {
        return service.updatePosition(maViTri, body.tenViTri(), body.maKhuVuc(), body.sucChua(), body.loaiViTri());
    }

    @DeleteMapping("/{maViTri}")
    public ResponseEntity<Void> delete(@PathVariable String maViTri) {
        service.deletePosition(maViTri);
        return ResponseEntity.noContent().build();
    }

    public record CreatePositionRequest(String maViTri,
        @NotBlank String maKhuVuc,
        @NotBlank @Size(max = 255) String tenViTri,
        @NotNull @Min(0) Integer sucChua,
        @NotBlank @Pattern(regexp = "Lưu trữ|Lấy hàng|Hư hỏng") String loaiViTri) {}

    public record UpdatePositionRequest(@NotBlank @Size(max = 255) String tenViTri,
        String maKhuVuc,
        @Min(0) Integer sucChua,
        @Pattern(regexp = "Lưu trữ|Lấy hàng|Hư hỏng") String loaiViTri) {}
}
