package vn.edu.dbms.bluestock.partner.application;

import java.util.List;
import java.util.Locale;
import java.util.function.Supplier;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.edu.dbms.bluestock.partner.application.PartnerException.Kind;
import vn.edu.dbms.bluestock.partner.application.PartnerModels.Page;
import vn.edu.dbms.bluestock.partner.application.PartnerModels.RecipientView;
import vn.edu.dbms.bluestock.partner.application.PartnerModels.SupplierView;
import vn.edu.dbms.bluestock.partner.infrastructure.PartnerJdbcRepository;

@Service
public class PartnerService {
    private final PartnerJdbcRepository repository;

    public PartnerService(PartnerJdbcRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public Page<SupplierView> suppliers(int page, int size, String query) {
        return repository.suppliers(page, size, normalizedQuery(page, size, query));
    }

    @Transactional(readOnly = true)
    public SupplierView supplier(String code) {
        return repository.supplier(normalizeCode(code)).orElseThrow(() ->
            new PartnerException(Kind.NOT_FOUND, "SUPPLIER_NOT_FOUND", "Không tìm thấy nhà cung cấp"));
    }

    @Transactional
    public SupplierView createSupplier(String code, String name, String address,
        String phone, String email) {
        String normalizedCode = resolveCode(code, repository::nextSupplierCode, "NCC001");
        try {
            repository.insertSupplier(normalizedCode, name.trim(), optionalText(address),
                optionalText(phone), optionalText(email));
        } catch (DuplicateKeyException exception) {
            throw new PartnerException(Kind.CONFLICT, "SUPPLIER_CODE_EXISTS", "Mã nhà cung cấp đã tồn tại");
        }
        return supplier(normalizedCode);
    }

    @Transactional
    public SupplierView updateSupplier(String code, String name, String address,
        String phone, String email) {
        String normalizedCode = normalizeCode(code);
        if (repository.updateSupplier(normalizedCode, name.trim(), optionalText(address),
            optionalText(phone), optionalText(email)) == 0) {
            throw new PartnerException(Kind.NOT_FOUND, "SUPPLIER_NOT_FOUND", "Không tìm thấy nhà cung cấp");
        }
        return supplier(normalizedCode);
    }

    @Transactional
    public void deleteSupplier(String code) {
        String normalizedCode = normalizeCode(code);
        try {
            if (repository.deleteSupplier(normalizedCode) == 0) {
                throw new PartnerException(Kind.NOT_FOUND, "SUPPLIER_NOT_FOUND", "Không tìm thấy nhà cung cấp");
            }
        } catch (DataIntegrityViolationException exception) {
            throw new PartnerException(Kind.CONFLICT, "SUPPLIER_IN_USE",
                "Nhà cung cấp đã được sản phẩm hoặc chứng từ tham chiếu");
        }
    }

    @Transactional(readOnly = true)
    public List<String> supplierProducts(String code) {
        String normalizedCode = normalizeCode(code);
        supplier(normalizedCode);
        return repository.supplierProducts(normalizedCode);
    }

    @Transactional
    public void addSupplierProduct(String supplierCode, String productCode) {
        String normalizedSupplier = normalizeCode(supplierCode);
        String normalizedProduct = normalizeCode(productCode);
        supplier(normalizedSupplier);
        if (!repository.productExists(normalizedProduct)) {
            throw new PartnerException(Kind.VALIDATION, "INVALID_PRODUCT", "Sản phẩm không tồn tại");
        }
        try {
            repository.addSupplierProduct(normalizedSupplier, normalizedProduct);
        } catch (DuplicateKeyException exception) {
            throw new PartnerException(Kind.CONFLICT, "SUPPLIER_PRODUCT_EXISTS",
                "Nhà cung cấp đã liên kết sản phẩm này");
        } catch (DataIntegrityViolationException exception) {
            throw new PartnerException(Kind.VALIDATION, "INVALID_REFERENCE",
                "Nhà cung cấp hoặc sản phẩm không còn tồn tại");
        }
    }

    @Transactional
    public void removeSupplierProduct(String supplierCode, String productCode) {
        String normalizedSupplier = normalizeCode(supplierCode);
        supplier(normalizedSupplier);
        if (repository.removeSupplierProduct(normalizedSupplier, normalizeCode(productCode)) == 0) {
            throw new PartnerException(Kind.NOT_FOUND, "SUPPLIER_PRODUCT_NOT_FOUND",
                "Không tìm thấy liên kết sản phẩm");
        }
    }

    @Transactional(readOnly = true)
    public Page<RecipientView> recipients(int page, int size, String query) {
        return repository.recipients(page, size, normalizedQuery(page, size, query));
    }

    @Transactional(readOnly = true)
    public RecipientView recipient(String code) {
        return repository.recipient(normalizeCode(code)).orElseThrow(() ->
            new PartnerException(Kind.NOT_FOUND, "RECIPIENT_NOT_FOUND", "Không tìm thấy đối tác nhận hàng"));
    }

    @Transactional
    public RecipientView createRecipient(String code, String name, String type,
        String address, String phone, String email) {
        String normalizedCode = resolveCode(code, repository::nextRecipientCode, "DT0001");
        try {
            repository.insertRecipient(normalizedCode, name.trim(), type.trim(),
                optionalText(address), optionalText(phone), optionalText(email));
        } catch (DuplicateKeyException exception) {
            throw new PartnerException(Kind.CONFLICT, "RECIPIENT_CODE_EXISTS", "Mã đối tác đã tồn tại");
        }
        return recipient(normalizedCode);
    }

    @Transactional
    public RecipientView updateRecipient(String code, String name, String type,
        String address, String phone, String email) {
        String normalizedCode = normalizeCode(code);
        if (repository.updateRecipient(normalizedCode, name.trim(), type.trim(),
            optionalText(address), optionalText(phone), optionalText(email)) == 0) {
            throw new PartnerException(Kind.NOT_FOUND, "RECIPIENT_NOT_FOUND", "Không tìm thấy đối tác nhận hàng");
        }
        return recipient(normalizedCode);
    }

    @Transactional
    public void deleteRecipient(String code) {
        String normalizedCode = normalizeCode(code);
        try {
            if (repository.deleteRecipient(normalizedCode) == 0) {
                throw new PartnerException(Kind.NOT_FOUND, "RECIPIENT_NOT_FOUND", "Không tìm thấy đối tác nhận hàng");
            }
        } catch (DataIntegrityViolationException exception) {
            throw new PartnerException(Kind.CONFLICT, "RECIPIENT_IN_USE",
                "Đối tác đã được sản phẩm hoặc chứng từ tham chiếu");
        }
    }

    @Transactional(readOnly = true)
    public List<String> recipientProducts(String code) {
        String normalizedCode = normalizeCode(code);
        recipient(normalizedCode);
        return repository.recipientProducts(normalizedCode);
    }

    @Transactional
    public void addRecipientProduct(String recipientCode, String productCode) {
        String normalizedRecipient = normalizeCode(recipientCode);
        String normalizedProduct = normalizeCode(productCode);
        recipient(normalizedRecipient);
        if (!repository.productExists(normalizedProduct)) {
            throw new PartnerException(Kind.VALIDATION, "INVALID_PRODUCT", "Sản phẩm không tồn tại");
        }
        try {
            repository.addRecipientProduct(normalizedRecipient, normalizedProduct);
        } catch (DuplicateKeyException exception) {
            throw new PartnerException(Kind.CONFLICT, "RECIPIENT_PRODUCT_EXISTS",
                "Đối tác đã liên kết sản phẩm này");
        } catch (DataIntegrityViolationException exception) {
            throw new PartnerException(Kind.VALIDATION, "INVALID_REFERENCE",
                "Đối tác hoặc sản phẩm không còn tồn tại");
        }
    }

    @Transactional
    public void removeRecipientProduct(String recipientCode, String productCode) {
        String normalizedRecipient = normalizeCode(recipientCode);
        recipient(normalizedRecipient);
        if (repository.removeRecipientProduct(normalizedRecipient, normalizeCode(productCode)) == 0) {
            throw new PartnerException(Kind.NOT_FOUND, "RECIPIENT_PRODUCT_NOT_FOUND",
                "Không tìm thấy liên kết sản phẩm");
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
            throw new PartnerException(Kind.VALIDATION, "INVALID_CODE", "Mã phải gồm 1–6 ký tự chữ hoặc số");
        }
        return normalized;
    }

    private static String normalizedQuery(int page, int size, String query) {
        if (page < 0 || page > 1_000_000 || size < 1 || size > 100) {
            throw new PartnerException(Kind.VALIDATION, "INVALID_PAGINATION", "page hoặc size không hợp lệ");
        }
        String normalized = optionalText(query);
        if (normalized != null && normalized.length() > 100) {
            throw new PartnerException(Kind.VALIDATION, "INVALID_QUERY", "Từ khóa tìm kiếm quá dài");
        }
        return normalized;
    }

    private static String optionalText(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
