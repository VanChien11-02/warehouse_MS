package vn.edu.dbms.bluestock.catalog.application;

import java.util.Locale;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.edu.dbms.bluestock.catalog.application.ProductModels.ProductData;
import vn.edu.dbms.bluestock.catalog.application.ProductModels.ProductPage;
import vn.edu.dbms.bluestock.catalog.application.ProductModels.ProductView;
import vn.edu.dbms.bluestock.catalog.infrastructure.ProductJdbcRepository;

@Service
public class ProductService {
    private final ProductJdbcRepository repository;

    public ProductService(ProductJdbcRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public ProductPage list(int page, int size, String query) {
        if (page < 0 || page > 1_000_000 || size < 1 || size > 100) {
            throw new ProductException(ProductException.Kind.VALIDATION,
                "INVALID_PAGINATION", "page hoặc size không hợp lệ");
        }
        String normalizedQuery = query == null || query.isBlank() ? null : query.trim();
        if (normalizedQuery != null && normalizedQuery.length() > 100) {
            throw new ProductException(ProductException.Kind.VALIDATION,
                "INVALID_QUERY", "Từ khóa tìm kiếm quá dài");
        }
        return repository.findPage(page, size, normalizedQuery);
    }

    @Transactional(readOnly = true)
    public ProductView get(String code) {
        return repository.findByCode(normalizeCode(code))
            .orElseThrow(() -> new ProductException(ProductException.Kind.NOT_FOUND,
                "PRODUCT_NOT_FOUND", "Không tìm thấy sản phẩm"));
    }

    @Transactional
    public ProductView create(String code, String category, String unit, ProductData data) {
        String productCode = resolveCode(code);
        String categoryCode = normalizeCode(category);
        String unitCode = normalizeCode(unit);
        if (!repository.categoryExists(categoryCode) || !repository.unitExists(unitCode)) {
            throw invalidReference();
        }
        try {
            repository.insert(productCode, categoryCode, unitCode, normalizeData(data));
        } catch (DuplicateKeyException exception) {
            throw new ProductException(ProductException.Kind.CONFLICT,
                "PRODUCT_CODE_EXISTS", "Mã sản phẩm đã tồn tại");
        } catch (DataIntegrityViolationException exception) {
            throw invalidReference();
        }
        return get(productCode);
    }

    @Transactional
    public ProductView update(String code, ProductData data) {
        String productCode = normalizeCode(code);
        if (repository.update(productCode, normalizeData(data)) == 0) {
            throw new ProductException(ProductException.Kind.NOT_FOUND,
                "PRODUCT_NOT_FOUND", "Không tìm thấy sản phẩm");
        }
        return get(productCode);
    }

    @Transactional
    public void delete(String code) {
        String productCode = normalizeCode(code);
        try {
            if (repository.delete(productCode) == 0) {
                throw new ProductException(ProductException.Kind.NOT_FOUND,
                    "PRODUCT_NOT_FOUND", "Không tìm thấy sản phẩm");
            }
        } catch (DataIntegrityViolationException exception) {
            throw new ProductException(ProductException.Kind.CONFLICT,
                "PRODUCT_IN_USE", "Sản phẩm đã được tham chiếu");
        }
    }

    private String resolveCode(String code) {
        if (code == null || code.isBlank()) {
            String generated = repository.nextCode();
            return generated == null || generated.isBlank() ? "SP0001" : normalizeCode(generated);
        }
        return normalizeCode(code);
    }

    private static String normalizeCode(String code) {
        String normalized = code == null ? "" : code.trim().toUpperCase(Locale.ROOT);
        if (!normalized.matches("[A-Z0-9]{1,6}")) {
            throw new ProductException(ProductException.Kind.VALIDATION,
                "INVALID_CODE", "Mã phải gồm 1–6 ký tự chữ hoặc số");
        }
        return normalized;
    }

    private static ProductData normalizeData(ProductData data) {
        return new ProductData(data.tenSanPham().trim(),
            data.giaNhapMacDinh(), data.giaBanMacDinh());
    }

    private static ProductException invalidReference() {
        return new ProductException(ProductException.Kind.VALIDATION,
            "INVALID_REFERENCE", "Loại sản phẩm hoặc đơn vị tính không tồn tại");
    }
}
