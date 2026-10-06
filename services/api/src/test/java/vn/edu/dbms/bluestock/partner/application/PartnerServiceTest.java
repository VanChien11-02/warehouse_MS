package vn.edu.dbms.bluestock.partner.application;

import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.DuplicateKeyException;
import vn.edu.dbms.bluestock.partner.application.PartnerModels.SupplierView;
import vn.edu.dbms.bluestock.partner.infrastructure.PartnerJdbcRepository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class PartnerServiceTest {
    private final PartnerJdbcRepository repository = Mockito.mock(PartnerJdbcRepository.class);
    private final PartnerService service = new PartnerService(repository);

    @Test
    void mappingRequiresExistingProduct() {
        when(repository.supplier("NCC001")).thenReturn(Optional.of(
            new SupplierView("NCC001", "Nhà cung cấp", null, null, null)));
        PartnerException error = assertThrows(PartnerException.class,
            () -> service.addSupplierProduct("ncc001", "sp0001"));
        assertEquals("INVALID_PRODUCT", error.code());
    }

    @Test
    void duplicateMappingHasStableConflictCode() {
        when(repository.supplier("NCC001")).thenReturn(Optional.of(
            new SupplierView("NCC001", "Nhà cung cấp", null, null, null)));
        when(repository.productExists("SP0001")).thenReturn(true);
        Mockito.doThrow(new DuplicateKeyException("duplicate"))
            .when(repository).addSupplierProduct("NCC001", "SP0001");
        PartnerException error = assertThrows(PartnerException.class,
            () -> service.addSupplierProduct("ncc001", "sp0001"));
        assertEquals("SUPPLIER_PRODUCT_EXISTS", error.code());
    }

    @Test
    void referencedSupplierCannotBeDeleted() {
        Mockito.doThrow(new DataIntegrityViolationException("foreign key"))
            .when(repository).deleteSupplier("NCC001");
        PartnerException error = assertThrows(PartnerException.class,
            () -> service.deleteSupplier("ncc001"));
        assertEquals("SUPPLIER_IN_USE", error.code());
        verify(repository).deleteSupplier("NCC001");
    }
}
