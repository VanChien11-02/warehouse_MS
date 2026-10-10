package vn.edu.dbms.bluestock.inbound.application;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.dao.DataIntegrityViolationException;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.AllocationData;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.LineData;
import vn.edu.dbms.bluestock.inbound.infrastructure.InboundJdbcRepository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class InboundServiceTest {
    private final InboundJdbcRepository repository = mock(InboundJdbcRepository.class);
    private final InboundService service = new InboundService(repository, new ObjectMapper());

    @Test
    void duplicateProductLineIsRejectedBeforeWriting() {
        var lines = List.of(new LineData("sp0001", 1, BigDecimal.ONE),
            new LineData("SP0001", 2, BigDecimal.ONE));
        var error = assertThrows(InboundException.class,
            () -> service.create("NCC001", "NV0001", null, lines));
        assertEquals("DUPLICATE_PRODUCT", error.code());
    }

    @Test
    void normalizesCodesAndKeepsPriceAsBigDecimal() {
        when(repository.nextCodeNumber()).thenReturn(1);
        when(repository.findByCode("PN0001")).thenReturn(Optional.of(new InboundModels.InboundView(
            "PN0001", null, "NCC001", "Nhà cung cấp", "NV0001", "NHAP", null, null,
            List.of())));
        service.create(" ncc001 ", " nv0001 ", null,
            List.of(new LineData(" sp0001 ", 2, new BigDecimal("1.2345"))));
        verify(repository).insertLine("PN0001",
            new LineData("SP0001", 2, new BigDecimal("1.2345")));
    }

    @Test
    void capacityErrorFromProcedureBecomesConflict() {
        when(repository.complete(eq("PN0001"), any())).thenThrow(
            new DataIntegrityViolationException("posting failed",
                new SQLException("capacity", "S0001", 51112)));
        var error = assertThrows(InboundException.class,
            () -> service.complete("PN0001", List.of(
                new AllocationData("SP0001", "VT0001", 2, null, null))));
        assertEquals("CAPACITY_EXCEEDED", error.code());
        assertEquals(InboundException.Kind.CONFLICT, error.kind());
    }

    @Test
    void missingInboundFromProcedureBecomesNotFound() {
        when(repository.complete(eq("PN9999"), any())).thenThrow(
            new DataIntegrityViolationException("posting failed",
                new SQLException("missing", "S0001", 51101)));
        var error = assertThrows(InboundException.class,
            () -> service.complete("PN9999", List.of(
                new AllocationData("SP0001", "VT0001", 2, LocalDate.of(2026, 1, 1), null))));
        assertEquals("INBOUND_NOT_FOUND", error.code());
    }

    @Test
    void serializesBusinessDatesAsIsoStringsForProcedure() {
        service.complete("PN0001", List.of(new AllocationData("SP0001", "VT0001", 2,
            LocalDate.of(2026, 1, 1), LocalDate.of(2026, 12, 31))));
        var json = ArgumentCaptor.forClass(String.class);
        verify(repository).complete(eq("PN0001"), json.capture());
        assertTrue(json.getValue().contains("\"ngaySanXuat\":\"2026-01-01\""));
        assertTrue(json.getValue().contains("\"hanSuDung\":\"2026-12-31\""));
    }
}
