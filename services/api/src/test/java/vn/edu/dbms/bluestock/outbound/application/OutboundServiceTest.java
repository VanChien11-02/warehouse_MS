package vn.edu.dbms.bluestock.outbound.application;

import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import vn.edu.dbms.bluestock.inventory.application.AvailableStockQuery;
import vn.edu.dbms.bluestock.inventory.application.AvailableStockQuery.StockCandidate;
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.LineData;
import vn.edu.dbms.bluestock.outbound.infrastructure.OutboundJdbcRepository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class OutboundServiceTest {
    private final OutboundJdbcRepository repository = mock(OutboundJdbcRepository.class);
    private final AvailableStockQuery availableStock = mock(AvailableStockQuery.class);
    private final OutboundService service = new OutboundService(repository, availableStock);

    @Test
    void duplicateLotPositionIsRejectedBeforeWriting() {
        var lines = List.of(new LineData("lo0001", "vt0001", 1, BigDecimal.ONE),
            new LineData("LO0001", "VT0001", 2, BigDecimal.ONE));
        var error = assertThrows(OutboundException.class,
            () -> service.create("DT0001", "NV0001", null, lines));
        assertEquals("DUPLICATE_STOCK_SOURCE", error.code());
    }

    @Test
    void normalizesSourceCodesBeforeInsert() {
        when(repository.nextCodeNumber()).thenReturn(1);
        when(repository.findByCode("PX0001")).thenReturn(Optional.of(new OutboundModels.OutboundView(
            "PX0001", null, "DT0001", "Đối tác", "NV0001", "NHAP", null, null,
            List.of())));
        service.create(" dt0001 ", " nv0001 ", null,
            List.of(new LineData(" lo0001 ", " vt0001 ", 2, new BigDecimal("1.2345"))));
        verify(repository).insertLine("PX0001",
            new LineData("LO0001", "VT0001", 2, new BigDecimal("1.2345")));
    }

    @Test
    void fefoErrorFromProcedureBecomesConflict() {
        when(repository.complete(eq("PX0001"), any(LocalDate.class))).thenThrow(
            new DataIntegrityViolationException("posting failed",
                new SQLException("fefo", "S0001", 51209)));
        var error = assertThrows(OutboundException.class, () -> service.complete("PX0001"));
        assertEquals("FEFO_VIOLATION", error.code());
        assertEquals(OutboundException.Kind.CONFLICT, error.kind());
    }

    @Test
    void missingOutboundFromProcedureBecomesNotFound() {
        when(repository.complete(eq("PX9999"), any(LocalDate.class))).thenThrow(
            new DataIntegrityViolationException("posting failed",
                new SQLException("missing", "S0001", 51201)));
        var error = assertThrows(OutboundException.class, () -> service.complete("PX9999"));
        assertEquals("OUTBOUND_NOT_FOUND", error.code());
    }

    @Test
    void suggestionUsesEarlierExpiryBeforeLaterLot() {
        when(repository.findByCode("PX0001")).thenReturn(Optional.of(new OutboundModels.OutboundView(
            "PX0001", null, "DT0001", "Đối tác", "NV0001", "NHAP", null, null,
            List.of())));
        when(availableStock.findAvailable(eq("SP0001"), eq(null), any(LocalDate.class)))
            .thenReturn(List.of(
                new StockCandidate("LO0001", "VT0001", 3, LocalDate.of(2026, 11, 1)),
                new StockCandidate("LO0002", "VT0002", 5, LocalDate.of(2026, 12, 1))));
        var suggestion = service.suggest("PX0001", "sp0001", 5, null);
        assertEquals(0, suggestion.soLuongThieu());
        assertEquals(3, suggestion.phanBo().get(0).soLuong());
        assertEquals(2, suggestion.phanBo().get(1).soLuong());
    }
}
