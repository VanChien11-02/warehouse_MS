package vn.edu.dbms.bluestock.inventory.api;

import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import vn.edu.dbms.bluestock.auth.infrastructure.SecurityConfig;
import vn.edu.dbms.bluestock.inventory.application.InventoryModels.ProductStockSummaryPage;
import vn.edu.dbms.bluestock.inventory.application.InventoryModels.ProductStockSummaryView;
import vn.edu.dbms.bluestock.inventory.application.InventoryModels.StockFilter;
import vn.edu.dbms.bluestock.inventory.application.InventoryModels.StockPage;
import vn.edu.dbms.bluestock.inventory.application.InventoryService;
import vn.edu.dbms.bluestock.platform.api.ApiExceptionHandler;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(InventoryController.class)
@Import({SecurityConfig.class, InventoryExceptionHandler.class, ApiExceptionHandler.class})
class InventoryControllerTest {
    @Autowired
    private MockMvc mvc;

    @MockitoBean
    private InventoryService service;

    @MockitoBean
    private UserDetailsService userDetailsService;

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void accountantCanReadInventory() throws Exception {
        when(service.list(0, 20, new StockFilter("KHO001", null, null, null, null, true)))
            .thenReturn(new StockPage(List.of(), 0, 20, 0, 0));
        mvc.perform(get("/api/ton-kho").param("maKho", "KHO001")
                .param("chiKhaDung", "true"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.totalElements").value(0));
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void managerCanReadProductStockSummary() throws Exception {
        when(service.listByProduct(0, 20, "KHO001", "SP0001"))
            .thenReturn(new ProductStockSummaryPage(List.of(
                new ProductStockSummaryView("KHO001", "Kho mẫu", "SP0001",
                    "Mì hộp mẫu", "DVT001", 119L, 150L, new BigDecimal("1720000.0000"))),
                0, 20, 1, 1));
        mvc.perform(get("/api/ton-kho/theo-san-pham")
                .param("maKho", "KHO001")
                .param("maSanPham", "SP0001"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.items[0].soLuongTon").value(119))
            .andExpect(jsonPath("$.items[0].tongTonToanHeThong").value(150))
            .andExpect(jsonPath("$.items[0].giaTriTon").value(1720000.0000));
    }

    @Test
    void anonymousCannotReadInventory() throws Exception {
        mvc.perform(get("/api/ton-kho"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void invalidDateFilterReturnsBadRequest() throws Exception {
        mvc.perform(get("/api/ton-kho").param("hanSuDungTruoc", "07-10-2026"))
            .andExpect(status().isBadRequest());
    }
}
