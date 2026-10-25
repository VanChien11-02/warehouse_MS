package vn.edu.dbms.bluestock.catalog.api;

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
import vn.edu.dbms.bluestock.catalog.application.CatalogReferenceModels.CategoryView;
import vn.edu.dbms.bluestock.catalog.application.CatalogReferenceModels.Page;
import vn.edu.dbms.bluestock.catalog.application.CatalogReferenceService;

@RestController
@RequestMapping("/api/loai-san-pham")
public class CategoryController {
    private final CatalogReferenceService service;

    public CategoryController(CatalogReferenceService service) {
        this.service = service;
    }

    @GetMapping
    public Page<CategoryView> list(@RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size, @RequestParam(required = false) String q) {
        return service.categories(page, size, q);
    }

    @GetMapping("/{maLoai}")
    public CategoryView get(@PathVariable String maLoai) {
        return service.category(maLoai);
    }

    @PostMapping
    public ResponseEntity<CategoryView> create(@Valid @RequestBody CreateCategoryRequest body) {
        CategoryView created = service.createCategory(
            body.maLoai(), body.tenLoai(), body.moTa(), body.yeuCauBaoQuan());
        return ResponseEntity.created(URI.create("/api/loai-san-pham/" + created.maLoai()))
            .body(created);
    }

    @PutMapping("/{maLoai}")
    public CategoryView update(@PathVariable String maLoai, @Valid @RequestBody UpdateCategoryRequest body) {
        return service.updateCategory(maLoai, body.tenLoai(), body.moTa(), body.yeuCauBaoQuan());
    }

    @DeleteMapping("/{maLoai}")
    public ResponseEntity<Void> delete(@PathVariable String maLoai) {
        service.deleteCategory(maLoai);
        return ResponseEntity.noContent().build();
    }

    public record CreateCategoryRequest(
        String maLoai,
        @NotBlank @Size(max = 255) String tenLoai,
        @Size(max = 1000) String moTa,
        @Pattern(regexp = "Khô|Mát|Đông lạnh") String yeuCauBaoQuan
    ) {}

    public record UpdateCategoryRequest(
        @NotBlank @Size(max = 255) String tenLoai,
        @Size(max = 1000) String moTa,
        @Pattern(regexp = "Khô|Mát|Đông lạnh") String yeuCauBaoQuan
    ) {}
}
