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
import vn.edu.dbms.bluestock.audit.application.AuditTrail;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.AllocationData;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.DraftAllocation;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.LineData;
import vn.edu.dbms.bluestock.inbound.infrastructure.InboundJdbcRepository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

class InboundServiceTest {
    private final InboundJdbcRepository repository = mock(InboundJdbcRepository.class);
    private final AuditTrail audit = mock(AuditTrail.class);
    private final InboundService service = new InboundService(repository, new ObjectMapper(), audit);

    @Test
    void historyNormalizesFiltersAndTreatsBlankAsAbsent() {
        var from = LocalDate.of(2026, 10, 25);
        service.history(0, 20, " pn0001 ", " sp0001 ", "  ", from, from);
        verify(repository).findHistory(0, 20, "PN0001", "SP0001", null, from, from);
        verifyNoInteractions(audit);
    }

    @Test
    void historyRejectsBadPaginationDateRangeAndCodesBeforeQuerying() {
        assertEquals("INVALID_PAGINATION", assertThrows(InboundException.class,
            () -> service.history(-1, 20, null, null, null, null, null)).code());
        assertEquals("INVALID_PAGINATION", assertThrows(InboundException.class,
            () -> service.history(0, 101, null, null, null, null, null)).code());
        assertEquals("INVALID_DATE_RANGE", assertThrows(InboundException.class,
            () -> service.history(0, 20, null, null, null, LocalDate.of(2026, 10, 26), LocalDate.of(2026, 10, 25))).code());
        assertEquals("INVALID_CODE", assertThrows(InboundException.class,
            () -> service.history(0, 20, "';DROP", null, null, null, null)).code());
        verifyNoInteractions(repository, audit);
    }

    @Test
    void duplicateProductLineIsRejectedBeforeWriting() {
        var lines = List.of(new LineData("sp0001", 1, BigDecimal.ONE),
            new LineData("SP0001", 2, BigDecimal.ONE));
        var error = assertThrows(InboundException.class,
            () -> service.create("NCC001", "NV0001", null, lines, null));
        assertEquals("DUPLICATE_PRODUCT", error.code());
    }

    @Test
    void normalizesCodesAndKeepsPriceAsBigDecimal() {
        when(repository.nextCodeNumber()).thenReturn(1);
        when(repository.findByCode("PN0001")).thenReturn(Optional.of(new InboundModels.InboundView(
            "PN0001", null, "NCC001", "Nhà cung cấp", "NV0001", "NHAP", null, null,
            List.of(), List.of())));
        service.create(" ncc001 ", " nv0001 ", null,
            List.of(new LineData(" sp0001 ", 2, new BigDecimal("1.2345"))), null);
        verify(repository).insertLine("PN0001",
            new LineData("SP0001", 2, new BigDecimal("1.2345")));
    }

    @Test
    void savesEveryDraftAllocationIncludingAnIncompleteRow() {
        when(repository.nextCodeNumber()).thenReturn(1);
        when(repository.findByCode("PN0001")).thenReturn(Optional.of(new InboundModels.InboundView(
            "PN0001", null, "NCC001", "Nhà cung cấp", "NV0001", "NHAP", null, null,
            List.of(), List.of())));
        service.create("NCC001", "NV0001", null,
            List.of(new LineData("SP0001", 10, BigDecimal.ONE)), List.of(
                new DraftAllocation("SP0001", "VT0001", "6", "", ""),
                new DraftAllocation("SP0001", "", "4", "", "")));
        var savedJson = ArgumentCaptor.forClass(String.class);
        verify(repository).insertHeader(eq("PN0001"), eq("NCC001"), eq("NV0001"), eq(null),
            savedJson.capture());
        assertTrue(savedJson.getValue().contains("\"maViTri\":\"VT0001\""));
        assertTrue(savedJson.getValue().contains("\"maViTri\":\"\""));
        assertEquals(2, savedJson.getValue().split("maSanPham", -1).length - 1);
    }

    @Test
    void capacityErrorFromProcedureBecomesConflict() {
        when(repository.complete(eq("PN0001"), any(), eq("TK0001"))).thenThrow(
            new DataIntegrityViolationException("posting failed",
                new SQLException("capacity", "S0001", 51112)));
        var error = assertThrows(InboundException.class,
            () -> service.complete("PN0001", List.of(
                new AllocationData("SP0001", "VT0001", 2, null, null)), "TK0001"));
        assertEquals("CAPACITY_EXCEEDED", error.code());
        assertEquals(InboundException.Kind.CONFLICT, error.kind());
    }

    @Test
    void actualLotTriggerErrorBecomesActionableAllocationError() {
        when(repository.complete(eq("PN0001"), any(), eq("TK0001"))).thenThrow(
            new DataIntegrityViolationException("trigger rejected lot insert",
                new SQLException("lot upper bound", "S0001", 51820)));
        var error = assertThrows(InboundException.class,
            () -> service.complete("PN0001", List.of(
                new AllocationData("SP0001", "VT0001", 6, null, null),
                new AllocationData("SP0001", "VT0002", 5, null, null)), "TK0001"));
        assertEquals("ALLOCATION_EXCEEDS_LINE", error.code());
        assertEquals(InboundException.Kind.VALIDATION, error.kind());
    }

    @Test
    void underAllocationRemainsACompletionRule() {
        when(repository.complete(eq("PN0001"), any(), eq("TK0001"))).thenThrow(
            new DataIntegrityViolationException("completion rejected",
                new SQLException("under allocation", "S0001", 51108)));
        var error = assertThrows(InboundException.class,
            () -> service.complete("PN0001", List.of(
                new AllocationData("SP0001", "VT0001", 9, null, null)), "TK0001"));
        assertEquals("ALLOCATION_INCOMPLETE", error.code());
    }

    @Test
    void missingInboundFromProcedureBecomesNotFound() {
        when(repository.complete(eq("PN9999"), any(), eq("TK0001"))).thenThrow(
            new DataIntegrityViolationException("posting failed",
                new SQLException("missing", "S0001", 51101)));
        var error = assertThrows(InboundException.class,
            () -> service.complete("PN9999", List.of(
                new AllocationData("SP0001", "VT0001", 2, LocalDate.of(2026, 1, 1), null)), "TK0001"));
        assertEquals("INBOUND_NOT_FOUND", error.code());
    }

    @Test
    void serializesBusinessDatesAsIsoStringsForProcedure() {
        service.complete("PN0001", List.of(new AllocationData("SP0001", "VT0001", 2,
            LocalDate.of(2026, 1, 1), LocalDate.of(2026, 12, 31))), "TK0001");
        var json = ArgumentCaptor.forClass(String.class);
        verify(repository).complete(eq("PN0001"), json.capture(), eq("TK0001"));
        assertTrue(json.getValue().contains("\"ngaySanXuat\":\"2026-01-01\""));
        assertTrue(json.getValue().contains("\"hanSuDung\":\"2026-12-31\""));
    }

    @Test
    void completedInboundCannotBeEdited() {
        when(repository.lockedStatus("PN0001")).thenReturn(Optional.of("DA_HOAN_THANH"));
        var error = assertThrows(InboundException.class,
            () -> service.update("PN0001", "NCC001", null,
                List.of(new LineData("SP0001", 1, BigDecimal.ONE)), null));
        assertEquals("INBOUND_NOT_DRAFT", error.code());
        verify(repository).lockedStatus("PN0001");
        verifyNoMoreInteractions(repository);
    }

    @Test
    void cancelDraftPreservesDocumentAndChangesStatus() {
        when(repository.lockedStatus("PN0001")).thenReturn(Optional.of("NHAP"));
        when(repository.cancel("PN0001")).thenReturn(1);
        when(repository.findByCode("PN0001")).thenReturn(Optional.of(new InboundModels.InboundView(
            "PN0001", null, "NCC001", "Nhà cung cấp", "NV0001", "DA_HUY",
            null, null, List.of(), List.of())));
        assertEquals("DA_HUY", service.cancel("pn0001", "tk0001").trangThai());
        verify(repository).cancel("PN0001");
        verify(audit).record("TK0001", "CANCEL", "PHIEU_NHAP", "PN0001",
            java.util.Map.of("trangThai", "NHAP"), java.util.Map.of("trangThai", "DA_HUY"));
    }

    @Test
    void failedCancellationDoesNotWriteAudit() {
        when(repository.lockedStatus("PN0001")).thenReturn(Optional.of("NHAP"));
        var error = assertThrows(InboundException.class,
            () -> service.cancel("PN0001", "TK0001"));
        assertEquals("INBOUND_NOT_DRAFT", error.code());
        verifyNoInteractions(audit);
    }
}
