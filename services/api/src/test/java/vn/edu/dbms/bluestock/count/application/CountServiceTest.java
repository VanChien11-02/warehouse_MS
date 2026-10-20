package vn.edu.dbms.bluestock.count.application;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import vn.edu.dbms.bluestock.audit.application.AuditTrail;
import vn.edu.dbms.bluestock.count.application.CountModels.CountView;
import vn.edu.dbms.bluestock.count.infrastructure.CountJdbcRepository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class CountServiceTest {
    private final CountJdbcRepository repository = mock(CountJdbcRepository.class);
    private final AuditTrail audit = mock(AuditTrail.class);
    private final CountService service = new CountService(repository, audit);

    @Test
    void cancellationRecordsActorAfterStatusChange() {
        when(repository.lockedStatus("KK0001")).thenReturn(Optional.of("NHAP"));
        when(repository.cancel("KK0001")).thenReturn(1);
        when(repository.findByCode("KK0001")).thenReturn(Optional.of(new CountView(
            "KK0001", null, "NV0001", "VT0001", "DA_HUY", null, null, List.of())));

        assertEquals("DA_HUY", service.cancel("kk0001", "tk0001").trangThai());
        verify(audit).record("TK0001", "CANCEL", "PHIEU_KIEM_KE", "KK0001",
            Map.of("trangThai", "NHAP"), Map.of("trangThai", "DA_HUY"));
    }

    @Test
    void failedCancellationDoesNotWriteAudit() {
        when(repository.lockedStatus("KK0001")).thenReturn(Optional.of("NHAP"));
        CountException error = assertThrows(CountException.class,
            () -> service.cancel("KK0001", "TK0001"));
        assertEquals("COUNT_NOT_DRAFT", error.code());
        verifyNoInteractions(audit);
    }
}
