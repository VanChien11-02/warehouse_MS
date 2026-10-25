package vn.edu.dbms.bluestock.catalog.application;

import java.util.Optional;
import java.sql.SQLException;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.DuplicateKeyException;
import vn.edu.dbms.bluestock.catalog.application.CatalogReferenceModels.CategoryView;
import vn.edu.dbms.bluestock.catalog.infrastructure.CatalogReferenceJdbcRepository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class CatalogReferenceServiceTest {
    @Test
    void storageHistoryTriggerReturnsBusinessConflict() {
        var repository = mock(CatalogReferenceJdbcRepository.class);
        var service = new CatalogReferenceService(repository);
        when(repository.updateCategory("LSP001", "Đồ khô", null, "Mát"))
            .thenThrow(new DataIntegrityViolationException("trigger rejected",
                new SQLException("category has lots", "S0001", 51825)));
        var error = assertThrows(CatalogReferenceException.class,
            () -> service.updateCategory("LSP001", "Đồ khô", null, "Mát"));
        assertEquals("CATEGORY_STORAGE_LOCKED", error.code());
        assertEquals(CatalogReferenceException.Kind.CONFLICT, error.kind());
        org.mockito.Mockito.verify(repository, org.mockito.Mockito.never()).category("LSP001");
    }

    @Test
    void unchangedStorageAllowsNormalCategoryEdit() {
        var repository = mock(CatalogReferenceJdbcRepository.class);
        var service = new CatalogReferenceService(repository);
        when(repository.updateCategory("LSP001", "Tên mới", "Mô tả mới", "Khô")).thenReturn(1);
        when(repository.category("LSP001"))
            .thenReturn(Optional.of(new CategoryView("LSP001", "Tên mới", "Mô tả mới", "Khô")));
        assertEquals("Tên mới", service.updateCategory("LSP001", "Tên mới", "Mô tả mới", "Khô").tenLoai());
    }

    @Test
    void normalizesCategoryCodeAndOptionalDescription() {
        var repository = mock(CatalogReferenceJdbcRepository.class);
        var service = new CatalogReferenceService(repository);
        when(repository.category("LSP001"))
            .thenReturn(Optional.of(new CategoryView("LSP001", "Đồ khô", null, "Khô")));
        service.createCategory(" lsp001 ", " Đồ khô ", "   ", "Khô");
        verify(repository).insertCategory("LSP001", "Đồ khô", null, "Khô");
    }

    @Test
    void distinguishesDuplicateUnitNameFromCode() {
        var repository = mock(CatalogReferenceJdbcRepository.class);
        var service = new CatalogReferenceService(repository);
        doThrow(new DuplicateKeyException("duplicate"))
            .when(repository).insertUnit("DVT002", "Hộp");
        when(repository.unit("DVT002")).thenReturn(Optional.empty());
        var error = assertThrows(CatalogReferenceException.class,
            () -> service.createUnit("DVT002", "Hộp"));
        assertEquals("UNIT_NAME_EXISTS", error.code());
    }

    @Test
    void referencedUnitCannotBeDeleted() {
        var repository = mock(CatalogReferenceJdbcRepository.class);
        var service = new CatalogReferenceService(repository);
        when(repository.deleteUnit("DVT001"))
            .thenThrow(new DataIntegrityViolationException("referenced"));
        var error = assertThrows(CatalogReferenceException.class,
            () -> service.deleteUnit("DVT001"));
        assertEquals("UNIT_IN_USE", error.code());
    }

    @Test
    void missingUnitReturnsNotFound() {
        var service = new CatalogReferenceService(mock(CatalogReferenceJdbcRepository.class));
        var error = assertThrows(CatalogReferenceException.class,
            () -> service.unit("DVT001"));
        assertEquals("UNIT_NOT_FOUND", error.code());
    }
}
