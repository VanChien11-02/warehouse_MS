package vn.edu.dbms.bluestock.transfer.application;

import java.sql.SQLException;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import vn.edu.dbms.bluestock.transfer.application.TransferModels.LineData;
import vn.edu.dbms.bluestock.transfer.infrastructure.TransferJdbcRepository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

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
}
