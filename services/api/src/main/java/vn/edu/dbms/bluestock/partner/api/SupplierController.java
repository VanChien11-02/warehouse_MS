package vn.edu.dbms.bluestock.partner.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.net.URI;
import java.util.List;
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
import vn.edu.dbms.bluestock.partner.application.PartnerModels.Page;
import vn.edu.dbms.bluestock.partner.application.PartnerModels.SupplierView;
import vn.edu.dbms.bluestock.partner.application.PartnerService;

@RestController
@RequestMapping("/api/nha-cung-cap")
public class SupplierController {
    private final PartnerService service;

    public SupplierController(PartnerService service) {
        this.service = service;
    }

    @GetMapping
    public Page<SupplierView> list(@RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size, @RequestParam(required = false) String q) {
        return service.suppliers(page, size, q);
    }

    @GetMapping("/{maNhaCungCap}")
    public SupplierView get(@PathVariable String maNhaCungCap) {
        return service.supplier(maNhaCungCap);
    }

    @PostMapping
    public ResponseEntity<SupplierView> create(@Valid @RequestBody CreateSupplierRequest body) {
        SupplierView created = service.createSupplier(body.maNhaCungCap(), body.tenNhaCungCap(),
            body.diaChi(), body.soDienThoai(), body.email());
        return ResponseEntity.created(URI.create("/api/nha-cung-cap/" + created.maNhaCungCap()))
            .body(created);
    }

    @PutMapping("/{maNhaCungCap}")
    public SupplierView update(@PathVariable String maNhaCungCap,
        @Valid @RequestBody UpdateSupplierRequest body) {
        return service.updateSupplier(maNhaCungCap, body.tenNhaCungCap(), body.diaChi(),
            body.soDienThoai(), body.email());
    }

    @DeleteMapping("/{maNhaCungCap}")
    public ResponseEntity<Void> delete(@PathVariable String maNhaCungCap) {
        service.deleteSupplier(maNhaCungCap);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{maNhaCungCap}/san-pham")
    public List<String> products(@PathVariable String maNhaCungCap) {
        return service.supplierProducts(maNhaCungCap);
    }

    @PostMapping("/{maNhaCungCap}/san-pham/{maSanPham}")
    public ResponseEntity<Void> addProduct(@PathVariable String maNhaCungCap,
        @PathVariable String maSanPham) {
        service.addSupplierProduct(maNhaCungCap, maSanPham);
        return ResponseEntity.created(URI.create("/api/nha-cung-cap/" + maNhaCungCap
            + "/san-pham/" + maSanPham)).build();
    }

    @DeleteMapping("/{maNhaCungCap}/san-pham/{maSanPham}")
    public ResponseEntity<Void> removeProduct(@PathVariable String maNhaCungCap,
        @PathVariable String maSanPham) {
        service.removeSupplierProduct(maNhaCungCap, maSanPham);
        return ResponseEntity.noContent().build();
    }

    public record CreateSupplierRequest(@NotBlank String maNhaCungCap,
        @NotBlank @Size(max = 255) String tenNhaCungCap,
        @Size(max = 500) String diaChi,
        @Size(max = 20) String soDienThoai,
        @Email @Size(max = 255) String email) {}

    public record UpdateSupplierRequest(
        @NotBlank @Size(max = 255) String tenNhaCungCap,
        @Size(max = 500) String diaChi,
        @Size(max = 20) String soDienThoai,
        @Email @Size(max = 255) String email) {}
}
