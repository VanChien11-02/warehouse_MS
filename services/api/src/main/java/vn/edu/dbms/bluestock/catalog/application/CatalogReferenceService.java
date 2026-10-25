package vn.edu.dbms.bluestock.catalog.application;

import java.util.Locale;
import java.util.function.Supplier;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.edu.dbms.bluestock.catalog.application.CatalogReferenceException.Kind;
import vn.edu.dbms.bluestock.catalog.application.CatalogReferenceModels.CategoryView;
import vn.edu.dbms.bluestock.catalog.application.CatalogReferenceModels.Page;
import vn.edu.dbms.bluestock.catalog.application.CatalogReferenceModels.UnitView;
import vn.edu.dbms.bluestock.catalog.infrastructure.CatalogReferenceJdbcRepository;
import vn.edu.dbms.bluestock.platform.infrastructure.SqlErrorNumbers;

@Service
public class CatalogReferenceService {
    private final CatalogReferenceJdbcRepository repository;

    public CatalogReferenceService(CatalogReferenceJdbcRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public Page<CategoryView> categories(int page, int size, String query) {
        return repository.categories(page, size, normalizedQuery(page, size, query));
    }

    @Transactional(readOnly = true)
    public Page<UnitView> units(int page, int size, String query) {
        return repository.units(page, size, normalizedQuery(page, size, query));
    }

    @Transactional(readOnly = true)
    public CategoryView category(String code) {
        return repository.category(normalizeCode(code)).orElseThrow(() ->
            new CatalogReferenceException(Kind.NOT_FOUND, "CATEGORY_NOT_FOUND", "Không tìm thấy loại sản phẩm"));
    }

    @Transactional(readOnly = true)
    public UnitView unit(String code) {
        return repository.unit(normalizeCode(code)).orElseThrow(() ->
            new CatalogReferenceException(Kind.NOT_FOUND, "UNIT_NOT_FOUND", "Không tìm thấy đơn vị tính"));
    }

    @Transactional
    public CategoryView createCategory(String code, String name, String description, String storageRequirement) {
        String normalizedCode = resolveCode(code, repository::nextCategoryCode, "LSP001");
        try {
            repository.insertCategory(normalizedCode, name.trim(), optionalText(description), storageRequirement);
        } catch (DuplicateKeyException exception) {
            throw new CatalogReferenceException(Kind.CONFLICT, "CATEGORY_CODE_EXISTS",
                "Mã loại sản phẩm đã tồn tại");
        }
        return category(normalizedCode);
    }

    @Transactional
    public CategoryView updateCategory(String code, String name, String description, String storageRequirement) {
        String normalizedCode = normalizeCode(code);
        try {
            if (repository.updateCategory(normalizedCode, name.trim(), optionalText(description), storageRequirement) == 0) {
                throw new CatalogReferenceException(Kind.NOT_FOUND, "CATEGORY_NOT_FOUND",
                    "Không tìm thấy loại sản phẩm");
            }
        } catch (DataAccessException exception) {
            if (SqlErrorNumbers.from(exception) == 51825) {
                throw new CatalogReferenceException(Kind.CONFLICT, "CATEGORY_STORAGE_LOCKED",
                    "Không thể đổi yêu cầu bảo quản vì loại sản phẩm đã phát sinh lô hàng. Bạn vẫn có thể sửa tên và mô tả.");
            }
            throw exception;
        }
        return category(normalizedCode);
    }

    @Transactional
    public void deleteCategory(String code) {
        String normalizedCode = normalizeCode(code);
        try {
            if (repository.deleteCategory(normalizedCode) == 0) {
                throw new CatalogReferenceException(Kind.NOT_FOUND, "CATEGORY_NOT_FOUND",
                    "Không tìm thấy loại sản phẩm");
            }
        } catch (DataIntegrityViolationException exception) {
            throw new CatalogReferenceException(Kind.CONFLICT, "CATEGORY_IN_USE",
                "Loại sản phẩm đã được tham chiếu");
        }
    }

    @Transactional
    public UnitView createUnit(String code, String name) {
        String normalizedCode = resolveCode(code, repository::nextUnitCode, "DVT001");
        try {
            repository.insertUnit(normalizedCode, name.trim());
        } catch (DuplicateKeyException exception) {
            if (repository.unit(normalizedCode).isPresent()) {
                throw new CatalogReferenceException(Kind.CONFLICT, "UNIT_CODE_EXISTS",
                    "Mã đơn vị tính đã tồn tại");
            }
            throw new CatalogReferenceException(Kind.CONFLICT, "UNIT_NAME_EXISTS",
                "Tên đơn vị tính đã tồn tại");
        }
        return unit(normalizedCode);
    }

    @Transactional
    public UnitView updateUnit(String code, String name) {
        String normalizedCode = normalizeCode(code);
        try {
            if (repository.updateUnit(normalizedCode, name.trim()) == 0) {
                throw new CatalogReferenceException(Kind.NOT_FOUND, "UNIT_NOT_FOUND",
                    "Không tìm thấy đơn vị tính");
            }
        } catch (DuplicateKeyException exception) {
            throw new CatalogReferenceException(Kind.CONFLICT, "UNIT_NAME_EXISTS",
                "Tên đơn vị tính đã tồn tại");
        }
        return unit(normalizedCode);
    }

    @Transactional
    public void deleteUnit(String code) {
        String normalizedCode = normalizeCode(code);
        try {
            if (repository.deleteUnit(normalizedCode) == 0) {
                throw new CatalogReferenceException(Kind.NOT_FOUND, "UNIT_NOT_FOUND",
                    "Không tìm thấy đơn vị tính");
            }
        } catch (DataIntegrityViolationException exception) {
            throw new CatalogReferenceException(Kind.CONFLICT, "UNIT_IN_USE",
                "Đơn vị tính đã được tham chiếu");
        }
    }

    private static String resolveCode(String code, Supplier<String> generator, String fallback) {
        if (code == null || code.isBlank()) {
            String generated = generator.get();
            return generated == null || generated.isBlank() ? fallback : normalizeCode(generated);
        }
        return normalizeCode(code);
    }

    private static String normalizeCode(String code) {
        String normalized = code == null ? "" : code.trim().toUpperCase(Locale.ROOT);
        if (!normalized.matches("[A-Z0-9]{1,6}")) {
            throw new CatalogReferenceException(Kind.VALIDATION, "INVALID_CODE",
                "Mã phải gồm 1–6 ký tự chữ hoặc số");
        }
        return normalized;
    }

    private static String normalizedQuery(int page, int size, String query) {
        if (page < 0 || page > 1_000_000 || size < 1 || size > 100) {
            throw new CatalogReferenceException(Kind.VALIDATION, "INVALID_PAGINATION",
                "page hoặc size không hợp lệ");
        }
        String normalized = query == null || query.isBlank() ? null : query.trim();
        if (normalized != null && normalized.length() > 100) {
            throw new CatalogReferenceException(Kind.VALIDATION, "INVALID_QUERY",
                "Từ khóa tìm kiếm quá dài");
        }
        return normalized;
    }

    private static String optionalText(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
