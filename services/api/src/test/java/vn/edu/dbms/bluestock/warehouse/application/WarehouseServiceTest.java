package vn.edu.dbms.bluestock.warehouse.application;

import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.DuplicateKeyException;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseModels.AreaView;
import vn.edu.dbms.bluestock.warehouse.infrastructure.WarehouseJdbcRepository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class WarehouseServiceTest {
    @Test
    void createsAreaWithNormalizedParentCode() {
        var repository = mock(WarehouseJdbcRepository.class);
        var service = new WarehouseService(repository);
        when(repository.warehouse("KHO001"))
            .thenReturn(Optional.of(new WarehouseModels.WarehouseView("KHO001", "Kho chính", null)));
        when(repository.area("KV0001"))
            .thenReturn(Optional.of(new AreaView("KV0001", "KHO001", "Kho chính", "Khu khô", "Khô")));
        service.createArea(" kv0001 ", " kho001 ", " Khu khô ", "Khô");
        verify(repository).insertArea("KV0001", "KHO001", "Khu khô", "Khô");
    }

    @Test
    void duplicateWarehouseNameReturnsConflict() {
        var repository = mock(WarehouseJdbcRepository.class);
        var service = new WarehouseService(repository);
        doThrow(new DuplicateKeyException("duplicate"))
            .when(repository).insertWarehouse("KHO002", "Kho chính", null);
        var error = assertThrows(WarehouseException.class,
            () -> service.createWarehouse("KHO002", "Kho chính", null));
        assertEquals("WAREHOUSE_NAME_EXISTS", error.code());
    }

    @Test
    void areaInUseCannotBeDeleted() {
        var repository = mock(WarehouseJdbcRepository.class);
        var service = new WarehouseService(repository);
        when(repository.deleteArea("KV0001"))
            .thenThrow(new DataIntegrityViolationException("referenced"));
        var error = assertThrows(WarehouseException.class,
            () -> service.deleteArea("KV0001"));
        assertEquals("AREA_IN_USE", error.code());
    }
}
