package vn.edu.dbms.bluestock.audit.application;

import java.time.LocalDate;
import java.time.LocalDateTime;
import org.junit.jupiter.api.Test;
import vn.edu.dbms.bluestock.audit.infrastructure.AuditJdbcRepository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

class AuditServiceTest {
    private final AuditJdbcRepository repository = mock(AuditJdbcRepository.class);
    private final AuditService service = new AuditService(repository);

    @Test
    void filtersByBangkokBusinessDateInUtc() {
        service.list(LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 2),
            "tk0001", 0, 20);
        verify(repository).findPage(LocalDate.of(2026, 10, 1),
            LocalDate.of(2026, 10, 2),
            LocalDateTime.of(2026, 9, 30, 17, 0),
            LocalDateTime.of(2026, 10, 2, 17, 0), "TK0001", 0, 20);
    }

    @Test
    void invalidPeriodIsRejectedBeforeQuery() {
        AuditException error = assertThrows(AuditException.class,
            () -> service.list(LocalDate.of(2026, 10, 2),
                LocalDate.of(2026, 10, 1), null, 0, 20));
        assertEquals("INVALID_DATE_RANGE", error.code());
        verifyNoInteractions(repository);
    }
}
