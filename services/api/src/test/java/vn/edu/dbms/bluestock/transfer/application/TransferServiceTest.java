package vn.edu.dbms.bluestock.transfer.application;

import java.sql.SQLException;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import vn.edu.dbms.bluestock.transfer.application.TransferModels.LineData;
import vn.edu.dbms.bluestock.transfer.infrastructure.TransferJdbcRepository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;

class TransferServiceTest {
    private final TransferJdbcRepository repository = mock(TransferJdbcRepository.class);
    private final TransferService service = new TransferService(repository);

    @Test
    void sameSourceAndDestinationIsRejectedBeforeWriting() {
        TransferException error = assertThrows(TransferException.class,
            () -> service.create("NV0001", null,
                List.of(new LineData("LO0001", "vt0001", "VT0001", 1))));
        assertEquals("SAME_POSITION", error.code());
    }

    @Test
    void duplicateRouteIsRejectedBeforeWriting() {
        TransferException error = assertThrows(TransferException.class,
            () -> service.create("NV0001", null, List.of(
                new LineData("lo0001", "vt0001", "vt0002", 1),
                new LineData("LO0001", "VT0001", "VT0002", 2))));
        assertEquals("DUPLICATE_TRANSFER_LINE", error.code());
    }

    @Test
    void insufficientStockFromProcedureBecomesConflict() {
        when(repository.complete("PC0001")).thenThrow(
            new DataIntegrityViolationException("posting failed",
                new SQLException("stock", "S0001", 51306)));
        TransferException error = assertThrows(TransferException.class,
            () -> service.complete("pc0001"));
        assertEquals("INSUFFICIENT_STOCK", error.code());
        assertEquals(TransferException.Kind.CONFLICT, error.kind());
    }

    @Test
    void completedTransferCannotBeEdited() {
        when(repository.lockedStatus("PC0001")).thenReturn(Optional.of("DA_HOAN_THANH"));
        TransferException error = assertThrows(TransferException.class,
            () -> service.update("PC0001", null,
                List.of(new LineData("LO0001", "VT0001", "VT0002", 1))));
        assertEquals("TRANSFER_NOT_DRAFT", error.code());
        verify(repository).lockedStatus("PC0001");
        verifyNoMoreInteractions(repository);
    }

    @Test
    void cancelDraftPreservesDocumentAndChangesStatus() {
        when(repository.lockedStatus("PC0001")).thenReturn(Optional.of("NHAP"));
        when(repository.findByCode("PC0001")).thenReturn(Optional.of(
            new TransferModels.TransferView("PC0001", null, "NV0001", "DA_HUY",
                null, null, List.of())));
        assertEquals("DA_HUY", service.cancel("pc0001").trangThai());
        verify(repository).cancel("PC0001");
    }
}
