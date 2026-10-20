package vn.edu.dbms.bluestock.inventory.application;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Locale;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.edu.dbms.bluestock.inventory.application.InventoryModels.StockFilter;
import vn.edu.dbms.bluestock.inventory.application.InventoryModels.StockPage;
import vn.edu.dbms.bluestock.inventory.infrastructure.InventoryJdbcRepository;

@Service
public class InventoryService {
    private static final ZoneId BUSINESS_ZONE = ZoneId.of("Asia/Bangkok");
    private final InventoryJdbcRepository repository;

    public InventoryService(InventoryJdbcRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public StockPage list(int page, int size, StockFilter filter) {
        if (page < 0 || page > 1_000_000 || size < 1 || size > 100) {
            throw new InventoryException("INVALID_PAGINATION", "page hoặc size không hợp lệ");
        }
        StockFilter normalized = new StockFilter(normalizeOptional(filter.maKho()),
            normalizeOptional(filter.maViTri()), normalizeOptional(filter.maSanPham()),
            normalizeOptional(filter.maLo()), filter.hanSuDungTruoc(), filter.chiKhaDung());
        LocalDate businessDate = LocalDate.now(BUSINESS_ZONE);
        return repository.findPage(page, size, normalized, businessDate);
    }

    private static String normalizeOptional(String code) {
        if (code == null) return null;
        String normalized = code.trim().toUpperCase(Locale.ROOT);
        if (!normalized.matches("[A-Z0-9]{1,6}")) {
            throw new InventoryException("INVALID_CODE", "Mã lọc phải gồm 1–6 ký tự chữ hoặc số");
        }
        return normalized;
    }
}
