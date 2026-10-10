package vn.edu.dbms.bluestock.catalog.api;

import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import vn.edu.dbms.bluestock.auth.infrastructure.SecurityConfig;
import vn.edu.dbms.bluestock.catalog.application.ProductException;
import vn.edu.dbms.bluestock.catalog.application.ProductModels.ProductPage;
import vn.edu.dbms.bluestock.catalog.application.ProductModels.ProductView;
import vn.edu.dbms.bluestock.catalog.application.ProductService;
import vn.edu.dbms.bluestock.platform.api.ApiExceptionHandler;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ProductController.class)
@Import({SecurityConfig.class, ProductExceptionHandler.class, ApiExceptionHandler.class})
class ProductControllerTest {
    @Autowired
    private MockMvc mvc;

    @MockitoBean
    private ProductService service;

    @MockitoBean
    private UserDetailsService userDetailsService;

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void anyRoleCanReadProductPage() throws Exception {
        when(service.list(0, 20, null)).thenReturn(new ProductPage(List.of(product()), 0, 20, 1, 1));

        mvc.perform(get("/api/san-pham"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.items[0].maSanPham").value("SP0001"))
            .andExpect(jsonPath("$.totalElements").value(1));
    }

    @Test
    void anonymousCannotReadProducts() throws Exception {
        mvc.perform(get("/api/san-pham"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void managerCanCreateProductWithCsrf() throws Exception {
        when(service.create(eq("SP0001"), eq("LSP001"), eq("DVT001"), any()))
            .thenReturn(product());

        mvc.perform(post("/api/san-pham").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(validBody()))
            .andExpect(status().isCreated())
            .andExpect(header().string("Location", "/api/san-pham/SP0001"))
            .andExpect(jsonPath("$.giaNhapMacDinh").value(10000.0000));
    }

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void accountantCannotCreateProduct() throws Exception {
        mvc.perform(post("/api/san-pham").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(validBody()))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void warehouseStaffCannotDeleteProduct() throws Exception {
        mvc.perform(delete("/api/san-pham/SP0001").with(csrf()))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLE_ADMIN")
    void invalidPriceIsRejected() throws Exception {
        mvc.perform(post("/api/san-pham").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(validBody().replace("10000.0000", "-1.0000")))
            .andExpect(status().isUnprocessableEntity())
            .andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
            .andExpect(jsonPath("$.fieldErrors[0].field").value("giaNhapMacDinh"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_ADMIN")
    void duplicateCodeReturnsConflict() throws Exception {
        when(service.create(eq("SP0001"), eq("LSP001"), eq("DVT001"), any()))
            .thenThrow(new ProductException(ProductException.Kind.CONFLICT,
                "PRODUCT_CODE_EXISTS", "Mã sản phẩm đã tồn tại"));

        mvc.perform(post("/api/san-pham").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(validBody()))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.code").value("PRODUCT_CODE_EXISTS"));
    }

    private static ProductView product() {
        return new ProductView("SP0001", "Sản phẩm mẫu", "LSP001", "Loại mẫu",
            "DVT001", "Hộp", new BigDecimal("10000.0000"), new BigDecimal("12000.0000"));
    }

    private static String validBody() {
        return """
            {"maSanPham":"SP0001","tenSanPham":"Sản phẩm mẫu",
             "maLoai":"LSP001","maDonViTinh":"DVT001",
             "giaNhapMacDinh":10000.0000,"giaBanMacDinh":12000.0000}
            """;
    }
}
