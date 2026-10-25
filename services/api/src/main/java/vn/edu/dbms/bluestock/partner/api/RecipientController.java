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
import vn.edu.dbms.bluestock.partner.application.PartnerModels.RecipientView;
import vn.edu.dbms.bluestock.partner.application.PartnerService;

@RestController
@RequestMapping("/api/doi-tac-nhan-hang")
public class RecipientController {
    private final PartnerService service;

    public RecipientController(PartnerService service) {
        this.service = service;
    }

    @GetMapping
    public Page<RecipientView> list(@RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size, @RequestParam(required = false) String q) {
        return service.recipients(page, size, q);
    }

    @GetMapping("/{maDoiTacNhanHang}")
    public RecipientView get(@PathVariable String maDoiTacNhanHang) {
        return service.recipient(maDoiTacNhanHang);
    }

    @PostMapping
    public ResponseEntity<RecipientView> create(@Valid @RequestBody CreateRecipientRequest body) {
        RecipientView created = service.createRecipient(body.maDoiTacNhanHang(), body.tenDoiTac(),
            body.loaiDoiTac(), body.diaChi(), body.soDienThoai(), body.email());
        return ResponseEntity.created(URI.create("/api/doi-tac-nhan-hang/" + created.maDoiTacNhanHang()))
            .body(created);
    }

    @PutMapping("/{maDoiTacNhanHang}")
    public RecipientView update(@PathVariable String maDoiTacNhanHang,
        @Valid @RequestBody UpdateRecipientRequest body) {
        return service.updateRecipient(maDoiTacNhanHang, body.tenDoiTac(), body.loaiDoiTac(),
            body.diaChi(), body.soDienThoai(), body.email());
    }

    @DeleteMapping("/{maDoiTacNhanHang}")
    public ResponseEntity<Void> delete(@PathVariable String maDoiTacNhanHang) {
        service.deleteRecipient(maDoiTacNhanHang);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{maDoiTacNhanHang}/san-pham")
    public List<String> products(@PathVariable String maDoiTacNhanHang) {
        return service.recipientProducts(maDoiTacNhanHang);
    }

    @PostMapping("/{maDoiTacNhanHang}/san-pham/{maSanPham}")
    public ResponseEntity<Void> addProduct(@PathVariable String maDoiTacNhanHang,
        @PathVariable String maSanPham) {
        service.addRecipientProduct(maDoiTacNhanHang, maSanPham);
        return ResponseEntity.created(URI.create("/api/doi-tac-nhan-hang/" + maDoiTacNhanHang
            + "/san-pham/" + maSanPham)).build();
    }

    @DeleteMapping("/{maDoiTacNhanHang}/san-pham/{maSanPham}")
    public ResponseEntity<Void> removeProduct(@PathVariable String maDoiTacNhanHang,
        @PathVariable String maSanPham) {
        service.removeRecipientProduct(maDoiTacNhanHang, maSanPham);
        return ResponseEntity.noContent().build();
    }

    public record CreateRecipientRequest(String maDoiTacNhanHang,
        @NotBlank @Size(max = 255) String tenDoiTac,
        @NotBlank @Size(max = 50) String loaiDoiTac,
        @Size(max = 500) String diaChi,
        @Size(max = 20) String soDienThoai,
        @Email @Size(max = 255) String email) {}

    public record UpdateRecipientRequest(
        @NotBlank @Size(max = 255) String tenDoiTac,
        @NotBlank @Size(max = 50) String loaiDoiTac,
        @Size(max = 500) String diaChi,
        @Size(max = 20) String soDienThoai,
        @Email @Size(max = 255) String email) {}
}
