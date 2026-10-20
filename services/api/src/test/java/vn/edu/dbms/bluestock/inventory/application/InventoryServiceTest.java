package vn.edu.dbms.bluestock.inventory.application;

import java.time.LocalDate;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import vn.edu.dbms.bluestock.inventory.application.InventoryModels.StockFilter;
import vn.edu.dbms.bluestock.inventory.infrastructure.InventoryJdbcRepository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

class InventoryServiceTest {
    @Test
    void normalizesFilterCodesBeforeQuery() {
        var repository = mock(InventoryJdbcRepository.class);
        var service = new InventoryService(repository);
        service.list(0, 20, new StockFilter(" kho001 ", null, " sp0001 ", null,
            LocalDate.of(2026, 12, 31), true));
        var filter = ArgumentCaptor.forClass(StockFilter.class);
        verify(repository).findPage(eq(0), eq(20), filter.capture(), any(LocalDate.class));
        assertEquals("KHO001", filter.getValue().maKho());
        assertEquals("SP0001", filter.getValue().maSanPham());
        assertEquals(true, filter.getValue().chiKhaDung());
    }

    @Test
    void invalidPageDoesNotReachDatabase() {
        var service = new InventoryService(mock(InventoryJdbcRepository.class));
        var error = assertThrows(InventoryException.class,
            () -> service.list(-1, 20, new StockFilter(null, null, null, null, null, false)));
        assertEquals("INVALID_PAGINATION", error.code());
    }
}
