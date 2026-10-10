package vn.edu.dbms.bluestock.catalog.application;

import java.math.BigDecimal;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.dao.DataIntegrityViolationException;
import vn.edu.dbms.bluestock.catalog.application.ProductModels.ProductData;
import vn.edu.dbms.bluestock.catalog.application.ProductModels.ProductView;
import vn.edu.dbms.bluestock.catalog.infrastructure.ProductJdbcRepository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ProductServiceTest {
    @Test
    void normalizesCodesBeforeInsert() {
        var repository = mock(ProductJdbcRepository.class);
        var service = new ProductService(repository);
        var data = new ProductData("  Sản phẩm mẫu  ", BigDecimal.ZERO, BigDecimal.ONE);
        when(repository.categoryExists("LSP001")).thenReturn(true);
        when(repository.unitExists("DVT001")).thenReturn(true);
        when(repository.findByCode("SP0001")).thenReturn(java.util.Optional.of(
            new ProductView("SP0001", "Sản phẩm mẫu", "LSP001", "Loại mẫu",
                "DVT001", "Hộp", BigDecimal.ZERO, BigDecimal.ONE)));

        service.create(" sp0001 ", " lsp001 ", " dvt001 ", data);

        verify(repository).insert("SP0001", "LSP001", "DVT001",
            new ProductData("Sản phẩm mẫu", BigDecimal.ZERO, BigDecimal.ONE));
    }

    @Test
    void mapsDuplicateCodeToConflict() {
        var repository = mock(ProductJdbcRepository.class);
        var service = new ProductService(repository);
        when(repository.categoryExists("LSP001")).thenReturn(true);
        when(repository.unitExists("DVT001")).thenReturn(true);
        org.mockito.Mockito.doThrow(new DuplicateKeyException("duplicate"))
            .when(repository).insert(any(), any(), any(), any());

        ProductException error = assertThrows(ProductException.class, () ->
            service.create("SP0001", "LSP001", "DVT001",
                new ProductData("Sản phẩm mẫu", BigDecimal.ZERO, BigDecimal.ONE)));

        assertEquals("PRODUCT_CODE_EXISTS", error.code());
    }

    @Test
    void referencedProductCannotBeDeleted() {
        var repository = mock(ProductJdbcRepository.class);
        var service = new ProductService(repository);
        when(repository.delete("SP0001"))
            .thenThrow(new DataIntegrityViolationException("referenced"));

        ProductException error = assertThrows(ProductException.class, () ->
            service.delete("SP0001"));

        assertEquals("PRODUCT_IN_USE", error.code());
    }
}
