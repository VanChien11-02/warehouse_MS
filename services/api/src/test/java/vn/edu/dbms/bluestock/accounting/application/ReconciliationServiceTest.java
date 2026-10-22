package vn.edu.dbms.bluestock.accounting.application;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import vn.edu.dbms.bluestock.accounting.application.ReconciliationModels.ReconciliationView;
import vn.edu.dbms.bluestock.accounting.infrastructure.ReconciliationJdbcRepository;
import vn.edu.dbms.bluestock.audit.application.AuditTrail;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ReconciliationServiceTest {
    private final ReconciliationJdbcRepository repository = mock(ReconciliationJdbcRepository.class);
    private final AuditTrail audit = mock(AuditTrail.class);
    private ReconciliationService service;

    @BeforeEach void setUp() { service = new ReconciliationService(repository, audit); }

    @Test void completedDocumentCanBeReconciledOnce() {
        when(repository.lockedDocumentStatus("NHAP", "PN0001"))
            .thenReturn(Optional.of("DA_HOAN_THANH"));
        when(repository.documentValue("NHAP", "PN0001")).thenReturn(new BigDecimal("120.0000"));
        when(repository.find("NHAP", "PN0001"))
            .thenReturn(Optional.empty(), Optional.of(view("KHOP")));

        assertEquals("KHOP", service.reconcile("nhap", "pn0001", new BigDecimal("120"),
            null, "TK0004").trangThai());
        verify(repository).insert("NHAP", "PN0001", new BigDecimal("120.0000"),
            new BigDecimal("120"), "KHOP", null, "TK0004");
        verify(audit).record("TK0004", "CREATE", "DOI_SOAT_GIA_TRI", "PN0001", null,
            view("KHOP"));
    }

    @Test void draftCannotBeReconciled() {
        when(repository.lockedDocumentStatus("XUAT", "PX0001")).thenReturn(Optional.of("NHAP"));
        assertEquals("DOCUMENT_NOT_COMPLETED", assertThrows(ReconciliationException.class,
            () -> service.reconcile("XUAT", "PX0001", BigDecimal.ZERO, null, "TK0004")).code());
    }

    @Test void discrepancyNeedsExplanation() {
        when(repository.lockedDocumentStatus("XUAT", "PX0001"))
            .thenReturn(Optional.of("DA_HOAN_THANH"));
        when(repository.documentValue("XUAT", "PX0001")).thenReturn(new BigDecimal("80"));
        assertEquals("DISCREPANCY_NOTE_REQUIRED", assertThrows(ReconciliationException.class,
            () -> service.reconcile("XUAT", "PX0001", new BigDecimal("75"), " ", "TK0004")).code());
    }

    @Test void secondReconciliationIsRejected() {
        when(repository.lockedDocumentStatus("NHAP", "PN0001"))
            .thenReturn(Optional.of("DA_HOAN_THANH"));
        when(repository.find("NHAP", "PN0001")).thenReturn(Optional.of(view("KHOP")));
        assertEquals("ALREADY_RECONCILED", assertThrows(ReconciliationException.class,
            () -> service.reconcile("NHAP", "PN0001", new BigDecimal("120"), null, "TK0004")).code());
    }

    private static ReconciliationView view(String status) {
        return new ReconciliationView("NHAP", "PN0001", new BigDecimal("120.0000"),
            new BigDecimal("120.0000"), BigDecimal.ZERO, status, null, "TK0004",
            OffsetDateTime.parse("2026-10-22T00:00:00Z"));
    }
}
