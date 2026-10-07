package vn.edu.dbms.bluestock.audit.application;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.Locale;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.edu.dbms.bluestock.audit.application.AuditModels.AuditPage;
import vn.edu.dbms.bluestock.audit.infrastructure.AuditJdbcRepository;

@Service
public class AuditService {
    private static final ZoneId BUSINESS_ZONE = ZoneId.of("Asia/Bangkok");
    private final AuditJdbcRepository repository;

    public AuditService(AuditJdbcRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public AuditPage list(LocalDate from, LocalDate through, String actor, int page, int size) {
        if (from == null || through == null || from.isAfter(through)
            || through.equals(LocalDate.MAX)) {
            throw new AuditException("INVALID_DATE_RANGE", "Khoảng ngày audit không hợp lệ");
        }
        if (page < 0 || page > 1_000_000 || size < 1 || size > 100) {
            throw new AuditException("INVALID_PAGINATION", "page hoặc size không hợp lệ");
        }
        String normalizedActor = actor == null ? null : actor.trim().toUpperCase(Locale.ROOT);
        if (normalizedActor != null && !normalizedActor.matches("[A-Z0-9]{1,6}")) {
            throw new AuditException("INVALID_CODE", "Mã tài khoản không hợp lệ");
        }
        LocalDateTime startUtc = LocalDateTime.ofInstant(
            from.atStartOfDay(BUSINESS_ZONE).toInstant(), ZoneOffset.UTC);
        LocalDateTime endUtc = LocalDateTime.ofInstant(
            through.plusDays(1).atStartOfDay(BUSINESS_ZONE).toInstant(), ZoneOffset.UTC);
        return repository.findPage(from, through, startUtc, endUtc, normalizedActor, page, size);
    }
}
