package vn.edu.dbms.bluestock.catalog.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
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
import vn.edu.dbms.bluestock.catalog.application.ProductModels.ProductData;
import vn.edu.dbms.bluestock.catalog.application.ProductModels.ProductPage;
import vn.edu.dbms.bluestock.catalog.application.ProductModels.ProductView;
import vn.edu.dbms.bluestock.catalog.application.ProductService;

@RestController
@RequestMapping("/api/san-pham")
public class ProductController {
    private final ProductService service;

    public ProductController(ProductService service) {
        this.service = service;
    }

    @GetMapping
    public ProductPage list(
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size,
        @RequestParam(required = false) String q
    ) {
        return service.list(page, size, q);
    }

    @GetMapping("/{maSanPham}")
    public ProductView get(@PathVariable String maSanPham) {
        return service.get(maSanPham);
    }

    @PostMapping
    public ResponseEntity<ProductView> create(@Valid @RequestBody CreateProductRequest body) {
        ProductView created = service.create(
            body.maSanPham(), body.maLoai(), body.maDonViTinh(), body.data());
        return ResponseEntity.created(URI.create("/api/san-pham/" + created.maSanPham()))
            .body(created);
    }

    @PutMapping("/{maSanPham}")
    public ProductView update(
        @PathVariable String maSanPham,
        @Valid @RequestBody UpdateProductRequest body
    ) {
        return service.update(maSanPham, body.data());
    }

    @DeleteMapping("/{maSanPham}")
    public ResponseEntity<Void> delete(@PathVariable String maSanPham) {
        service.delete(maSanPham);
        return ResponseEntity.noContent().build();
    }

    public record CreateProductRequest(
        String maSanPham,
        @NotBlank @Size(max = 255) String tenSanPham,
        @NotBlank String maLoai,
        @NotBlank String maDonViTinh,
        @NotNull @DecimalMin("0.0000") @Digits(integer = 15, fraction = 4)
            BigDecimal giaNhapMacDinh,
        @NotNull @DecimalMin("0.0000") @Digits(integer = 15, fraction = 4)
            BigDecimal giaBanMacDinh
    ) {
        ProductData data() {
            return new ProductData(tenSanPham, giaNhapMacDinh, giaBanMacDinh);
        }
    }

    public record UpdateProductRequest(
        @NotBlank @Size(max = 255) String tenSanPham,
        @NotNull @DecimalMin("0.0000") @Digits(integer = 15, fraction = 4)
            BigDecimal giaNhapMacDinh,
        @NotNull @DecimalMin("0.0000") @Digits(integer = 15, fraction = 4)
            BigDecimal giaBanMacDinh
    ) {
        ProductData data() {
            return new ProductData(tenSanPham, giaNhapMacDinh, giaBanMacDinh);
        }
    }
}
