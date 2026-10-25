package vn.edu.dbms.bluestock.warehouse.application;

import java.util.Locale;
import java.util.function.Supplier;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.edu.dbms.bluestock.platform.infrastructure.SqlErrorNumbers;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseException.Kind;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseModels.AreaView;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseModels.Page;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseModels.PositionView;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseModels.WarehouseView;
import vn.edu.dbms.bluestock.warehouse.infrastructure.WarehouseJdbcRepository;

@Service
public class WarehouseService {
    private final WarehouseJdbcRepository repository;

    public WarehouseService(WarehouseJdbcRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public Page<WarehouseView> warehouses(int page, int size, String query) {
        return repository.warehouses(page, size, normalizedQuery(page, size, query));
    }

    @Transactional(readOnly = true)
    public Page<AreaView> areas(int page, int size, String warehouseCode, String query) {
        String normalizedWarehouseCode = warehouseCode == null ? null : normalizeCode(warehouseCode);
        return repository.areas(page, size, normalizedWarehouseCode, normalizedQuery(page, size, query));
    }

    @Transactional(readOnly = true)
    public Page<PositionView> positions(int page, int size, String warehouseCode,
        String areaCode, String query) {
        String normalizedWarehouseCode = warehouseCode == null ? null : normalizeCode(warehouseCode);
        String normalizedAreaCode = areaCode == null ? null : normalizeCode(areaCode);
        return repository.positions(page, size, normalizedWarehouseCode, normalizedAreaCode,
            normalizedQuery(page, size, query));
    }

    @Transactional(readOnly = true)
    public WarehouseView warehouse(String code) {
        return repository.warehouse(normalizeCode(code)).orElseThrow(() ->
            new WarehouseException(Kind.NOT_FOUND, "WAREHOUSE_NOT_FOUND", "Không tìm thấy kho"));
    }

    @Transactional(readOnly = true)
    public AreaView area(String code) {
        return repository.area(normalizeCode(code)).orElseThrow(() ->
            new WarehouseException(Kind.NOT_FOUND, "AREA_NOT_FOUND", "Không tìm thấy khu vực"));
    }

    @Transactional(readOnly = true)
    public PositionView position(String code) {
        return repository.position(normalizeCode(code)).orElseThrow(() ->
            new WarehouseException(Kind.NOT_FOUND, "POSITION_NOT_FOUND", "Không tìm thấy vị trí"));
    }

    @Transactional
    public WarehouseView createWarehouse(String code, String name, String address) {
        String normalizedCode = resolveCode(code, repository::nextWarehouseCode, "KHO001");
        try {
            repository.insertWarehouse(normalizedCode, name.trim(), optionalText(address));
        } catch (DuplicateKeyException exception) {
            if (repository.warehouse(normalizedCode).isPresent()) {
                throw new WarehouseException(Kind.CONFLICT, "WAREHOUSE_CODE_EXISTS", "Mã kho đã tồn tại");
            }
            throw new WarehouseException(Kind.CONFLICT, "WAREHOUSE_NAME_EXISTS", "Tên kho đã tồn tại");
        }
        return warehouse(normalizedCode);
    }

    @Transactional
    public WarehouseView updateWarehouse(String code, String name, String address) {
        String normalizedCode = normalizeCode(code);
        try {
            if (repository.updateWarehouse(normalizedCode, name.trim(), optionalText(address)) == 0) {
                throw new WarehouseException(Kind.NOT_FOUND, "WAREHOUSE_NOT_FOUND", "Không tìm thấy kho");
            }
        } catch (DuplicateKeyException exception) {
            throw new WarehouseException(Kind.CONFLICT, "WAREHOUSE_NAME_EXISTS", "Tên kho đã tồn tại");
        }
        return warehouse(normalizedCode);
    }

    @Transactional
    public void deleteWarehouse(String code) {
        String normalizedCode = normalizeCode(code);
        try {
            if (repository.deleteWarehouse(normalizedCode) == 0) {
                throw new WarehouseException(Kind.NOT_FOUND, "WAREHOUSE_NOT_FOUND", "Không tìm thấy kho");
            }
        } catch (DataIntegrityViolationException exception) {
            throw new WarehouseException(Kind.CONFLICT, "WAREHOUSE_IN_USE",
                "Kho đã được khu vực hoặc chứng từ tham chiếu");
        }
    }

    @Transactional
    public AreaView createArea(String code, String warehouseCode, String name, String type) {
        String normalizedCode = resolveCode(code, repository::nextAreaCode, "KV0001");
        String normalizedWarehouseCode = normalizeCode(warehouseCode);
        if (repository.warehouse(normalizedWarehouseCode).isEmpty()) {
            throw new WarehouseException(Kind.VALIDATION, "INVALID_WAREHOUSE", "Kho không tồn tại");
        }
        try {
            repository.insertArea(normalizedCode, normalizedWarehouseCode, name.trim(), type);
        } catch (DuplicateKeyException exception) {
            if (repository.area(normalizedCode).isPresent()) {
                throw new WarehouseException(Kind.CONFLICT, "AREA_CODE_EXISTS", "Mã khu vực đã tồn tại");
            }
            throw new WarehouseException(Kind.CONFLICT, "AREA_NAME_EXISTS", "Tên khu vực đã tồn tại trong kho");
        } catch (DataIntegrityViolationException exception) {
            throw new WarehouseException(Kind.VALIDATION, "INVALID_WAREHOUSE", "Kho không tồn tại");
        }
        return area(normalizedCode);
    }

    @Transactional
    public AreaView updateArea(String code, String name) {
        String normalizedCode = normalizeCode(code);
        try {
            if (repository.updateArea(normalizedCode, name.trim()) == 0) {
                throw new WarehouseException(Kind.NOT_FOUND, "AREA_NOT_FOUND", "Không tìm thấy khu vực");
            }
        } catch (DuplicateKeyException exception) {
            throw new WarehouseException(Kind.CONFLICT, "AREA_NAME_EXISTS", "Tên khu vực đã tồn tại trong kho");
        }
        return area(normalizedCode);
    }

    @Transactional
    public void deleteArea(String code) {
        String normalizedCode = normalizeCode(code);
        try {
            if (repository.deleteArea(normalizedCode) == 0) {
                throw new WarehouseException(Kind.NOT_FOUND, "AREA_NOT_FOUND", "Không tìm thấy khu vực");
            }
        } catch (DataIntegrityViolationException exception) {
            throw new WarehouseException(Kind.CONFLICT, "AREA_IN_USE", "Khu vực đã được vị trí tham chiếu");
        }
    }

    @Transactional
    public PositionView createPosition(String code, String areaCode, String name, int capacity, String type) {
        String normalizedCode = resolveCode(code, repository::nextPositionCode, "VT0001");
        String normalizedAreaCode = normalizeCode(areaCode);
        if (repository.area(normalizedAreaCode).isEmpty()) {
            throw new WarehouseException(Kind.VALIDATION, "INVALID_AREA", "Khu vực không tồn tại");
        }
        try {
            repository.insertPosition(normalizedCode, normalizedAreaCode, name.trim(), capacity, type);
        } catch (DuplicateKeyException exception) {
            if (repository.position(normalizedCode).isPresent()) {
                throw new WarehouseException(Kind.CONFLICT, "POSITION_CODE_EXISTS", "Mã vị trí đã tồn tại");
            }
            throw new WarehouseException(Kind.CONFLICT, "POSITION_NAME_EXISTS",
                "Tên vị trí đã tồn tại trong khu vực");
        } catch (DataIntegrityViolationException exception) {
            throw new WarehouseException(Kind.VALIDATION, "INVALID_AREA", "Khu vực không tồn tại");
        }
        return position(normalizedCode);
    }

    @Transactional
    public PositionView updatePosition(String code, String name) {
        return updatePosition(code, name, null, null, null);
    }

    @Transactional
    public PositionView updatePosition(String code, String name, String areaCode, Integer capacity, String type) {
        String normalizedCode = normalizeCode(code);
        String normalizedAreaCode = areaCode == null || areaCode.isBlank() ? null : normalizeCode(areaCode);
        String normalizedType = optionalText(type);
        if (normalizedAreaCode != null && repository.area(normalizedAreaCode).isEmpty()) {
            throw new WarehouseException(Kind.VALIDATION, "INVALID_AREA", "Khu vực không tồn tại");
        }
        try {
            int updated = normalizedAreaCode == null && capacity == null && normalizedType == null
                ? repository.updatePosition(normalizedCode, name.trim())
                : repository.updatePosition(normalizedCode, name.trim(), normalizedAreaCode, capacity, normalizedType);
            if (updated == 0) {
                throw new WarehouseException(Kind.NOT_FOUND, "POSITION_NOT_FOUND", "Không tìm thấy vị trí");
            }
        } catch (DuplicateKeyException exception) {
            throw new WarehouseException(Kind.CONFLICT, "POSITION_NAME_EXISTS",
                "Tên vị trí đã tồn tại trong khu vực");
        } catch (DataAccessException exception) {
            if (SqlErrorNumbers.from(exception) == 52101) {
                throw new WarehouseException(Kind.CONFLICT, "POSITION_STOCK_PROTECTED",
                    "Vị trí có tồn không thể giảm sức chứa dưới tồn hoặc đổi khu vực/loại.");
            }
            if (exception instanceof DataIntegrityViolationException) {
                throw new WarehouseException(Kind.VALIDATION, "INVALID_AREA", "Khu vực không tồn tại");
            }
            throw exception;
        }
        return position(normalizedCode);
    }

    @Transactional
    public void deletePosition(String code) {
        String normalizedCode = normalizeCode(code);
        try {
            if (repository.deletePosition(normalizedCode) == 0) {
                throw new WarehouseException(Kind.NOT_FOUND, "POSITION_NOT_FOUND", "Không tìm thấy vị trí");
            }
        } catch (DataIntegrityViolationException exception) {
            throw new WarehouseException(Kind.CONFLICT, "POSITION_IN_USE", "Vị trí đã được tồn hoặc chứng từ tham chiếu");
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
            throw new WarehouseException(Kind.VALIDATION, "INVALID_CODE",
                "Mã phải gồm 1–6 ký tự chữ hoặc số");
        }
        return normalized;
    }

    private static String normalizedQuery(int page, int size, String query) {
        if (page < 0 || page > 1_000_000 || size < 1 || size > 100) {
            throw new WarehouseException(Kind.VALIDATION, "INVALID_PAGINATION",
                "page hoặc size không hợp lệ");
        }
        String normalized = query == null || query.isBlank() ? null : query.trim();
        if (normalized != null && normalized.length() > 100) {
            throw new WarehouseException(Kind.VALIDATION, "INVALID_QUERY", "Từ khóa tìm kiếm quá dài");
        }
        return normalized;
    }

    private static String optionalText(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
