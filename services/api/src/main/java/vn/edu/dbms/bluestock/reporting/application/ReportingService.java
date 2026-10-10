package vn.edu.dbms.bluestock.reporting.application;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.Locale;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.edu.dbms.bluestock.reporting.application.ReportingModels.MovementReportPage;
import vn.edu.dbms.bluestock.reporting.application.ReportingModels.CountDiscrepancyPage;
import vn.edu.dbms.bluestock.reporting.application.ReportingModels.ExpiringLotPage;
import vn.edu.dbms.bluestock.reporting.infrastructure.ReportingJdbcRepository;

@Service
public class ReportingService {
    private static final ZoneId BUSINESS_ZONE = ZoneId.of("Asia/Bangkok");
    private final ReportingJdbcRepository repository;

    public ReportingService(ReportingJdbcRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public MovementReportPage movementReport(LocalDate from, LocalDate through,
        String warehouseCode, String productCode, int page, int size) {
        validateRangeAndPage(from, through, page, size);
        LocalDateTime startUtc = LocalDateTime.ofInstant(
            from.atStartOfDay(BUSINESS_ZONE).toInstant(), ZoneOffset.UTC);
        LocalDateTime endUtc = LocalDateTime.ofInstant(
            through.plusDays(1).atStartOfDay(BUSINESS_ZONE).toInstant(), ZoneOffset.UTC);
        return repository.movementReport(from, through, startUtc, endUtc,
            normalizeOptional(warehouseCode), normalizeOptional(productCode), page, size);
    }

    @Transactional(readOnly = true)
    public CountDiscrepancyPage countDiscrepancies(LocalDate from, LocalDate through,
        String warehouseCode, String positionCode, int page, int size) {
        validateRangeAndPage(from, through, page, size);
        LocalDateTime startUtc = LocalDateTime.ofInstant(
            from.atStartOfDay(BUSINESS_ZONE).toInstant(), ZoneOffset.UTC);
        LocalDateTime endUtc = LocalDateTime.ofInstant(
            through.plusDays(1).atStartOfDay(BUSINESS_ZONE).toInstant(), ZoneOffset.UTC);
        return repository.countDiscrepancies(from, through, startUtc, endUtc,
            normalizeOptional(warehouseCode), normalizeOptional(positionCode), page, size);
    }

    @Transactional(readOnly = true)
    public ExpiringLotPage expiringLots(int days, String warehouseCode, int page, int size) {
        if (days < 0 || days > 3650) {
            throw new ReportingException("INVALID_DAYS", "Số ngày phải từ 0 đến 3650");
        }
        validatePage(page, size);
        return repository.expiringLots(days, normalizeOptional(warehouseCode), page, size);
    }

    private static void validateRangeAndPage(LocalDate from, LocalDate through, int page, int size) {
        if (from == null || through == null || from.isAfter(through)
            || through.equals(LocalDate.MAX)) {
            throw new ReportingException("INVALID_DATE_RANGE", "Khoảng ngày báo cáo không hợp lệ");
        }
        validatePage(page, size);
    }

    private static void validatePage(int page, int size) {
        if (page < 0 || page > 1_000_000 || size < 1 || size > 100) {
            throw new ReportingException("INVALID_PAGINATION", "page hoặc size không hợp lệ");
        }
    }

    private static String normalizeOptional(String code) {
        if (code == null) return null;
        String normalized = code.trim().toUpperCase(Locale.ROOT);
        if (!normalized.matches("[A-Z0-9]{1,6}")) {
            throw new ReportingException("INVALID_CODE", "Mã lọc phải gồm 1–6 ký tự chữ hoặc số");
        }
        return normalized;
    }
}
