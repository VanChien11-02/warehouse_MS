package vn.edu.dbms.bluestock.returning.application;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import vn.edu.dbms.bluestock.audit.application.AuditTrail;
import vn.edu.dbms.bluestock.returning.application.ReturnModels.ReturnView;
import vn.edu.dbms.bluestock.returning.infrastructure.ReturnJdbcRepository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class ReturnServiceTest {
    private final ReturnJdbcRepository repository = mock(ReturnJdbcRepository.class);
    private final AuditTrail audit = mock(AuditTrail.class);
    private final ReturnService service = new ReturnService(repository, audit);

    @Test
    void cancellationRecordsActorAfterStatusChange() {
        when(repository.lockedStatus("TH0001")).thenReturn(Optional.of("NHAP"));
        when(repository.cancel("TH0001")).thenReturn(1);
        when(repository.findByCode("TH0001")).thenReturn(Optional.of(new ReturnView(
            "TH0001", null, "PX0001", "NV0001", "DA_HUY", null, null, List.of())));

        assertEquals("DA_HUY", service.cancel("th0001", "tk0001").trangThai());
        verify(audit).record("TK0001", "CANCEL", "PHIEU_TRA_HANG", "TH0001",
            Map.of("trangThai", "NHAP"), Map.of("trangThai", "DA_HUY"));
    }

    @Test
    void failedCancellationDoesNotWriteAudit() {
        when(repository.lockedStatus("TH0001")).thenReturn(Optional.of("NHAP"));
        ReturnException error = assertThrows(ReturnException.class,
            () -> service.cancel("TH0001", "TK0001"));
        assertEquals("RETURN_NOT_DRAFT", error.code());
        verifyNoInteractions(audit);
    }
}
