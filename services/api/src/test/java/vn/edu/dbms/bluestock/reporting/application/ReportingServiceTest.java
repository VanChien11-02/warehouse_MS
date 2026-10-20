package vn.edu.dbms.bluestock.reporting.application;

import java.time.LocalDate;
import java.time.LocalDateTime;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import vn.edu.dbms.bluestock.reporting.infrastructure.ReportingJdbcRepository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

class ReportingServiceTest {
    private final ReportingJdbcRepository repository = Mockito.mock(ReportingJdbcRepository.class);
    private final ReportingService service = new ReportingService(repository);

    @Test
    void reportUsesBangkokDayBoundariesInUtc() {
        service.movementReport(LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 2),
            "kho001", "sp0001", 0, 20);
        verify(repository).movementReport(LocalDate.of(2026, 10, 1),
            LocalDate.of(2026, 10, 2),
            LocalDateTime.of(2026, 9, 30, 17, 0),
            LocalDateTime.of(2026, 10, 2, 17, 0),
            "KHO001", "SP0001", 0, 20);
    }

    @Test
    void reversedPeriodIsRejectedBeforeQuery() {
        ReportingException error = assertThrows(ReportingException.class,
            () -> service.movementReport(LocalDate.of(2026, 10, 2),
                LocalDate.of(2026, 10, 1), null, null, 0, 20));
        assertEquals("INVALID_DATE_RANGE", error.code());
        verifyNoInteractions(repository);
    }

    @Test
    void countDiscrepancyUsesCompletionDateInBusinessZone() {
        service.countDiscrepancies(LocalDate.of(2026, 10, 1),
            LocalDate.of(2026, 10, 2), "kho001", "vt0001", 0, 20);
        verify(repository).countDiscrepancies(LocalDate.of(2026, 10, 1),
            LocalDate.of(2026, 10, 2),
            LocalDateTime.of(2026, 9, 30, 17, 0),
            LocalDateTime.of(2026, 10, 2, 17, 0),
            "KHO001", "VT0001", 0, 20);
    }

    @Test
    void expiringLotsValidateDaysAndNormalizeWarehouse() {
        service.expiringLots(30, " kho001 ", 1, 10);
        verify(repository).expiringLots(30, "KHO001", 1, 10);
        ReportingException error = assertThrows(ReportingException.class,
            () -> service.expiringLots(-1, null, 0, 20));
        assertEquals("INVALID_DAYS", error.code());
    }
}
