package vn.edu.dbms.bluestock.catalog.api;

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
import vn.edu.dbms.bluestock.catalog.application.CatalogReferenceException;
import vn.edu.dbms.bluestock.catalog.application.CatalogReferenceModels.CategoryView;
import vn.edu.dbms.bluestock.catalog.application.CatalogReferenceModels.Page;
import vn.edu.dbms.bluestock.catalog.application.CatalogReferenceModels.UnitView;
import vn.edu.dbms.bluestock.catalog.application.CatalogReferenceService;
import vn.edu.dbms.bluestock.platform.api.ApiExceptionHandler;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest({CategoryController.class, UnitController.class})
@Import({SecurityConfig.class, ProductExceptionHandler.class, ApiExceptionHandler.class})
class CatalogReferenceControllerTest {
    @Autowired
    private MockMvc mvc;

    @MockitoBean
    private CatalogReferenceService service;

    @MockitoBean
    private UserDetailsService userDetailsService;

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void warehouseStaffCanReadCategories() throws Exception {
        when(service.categories(0, 20, null)).thenReturn(new Page<>(
            List.of(new CategoryView("LSP001", "Đồ khô", null, "Khô")), 0, 20, 1, 1));
        mvc.perform(get("/api/loai-san-pham"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.items[0].yeuCauBaoQuan").value("Khô"));
    }

    @Test
    void anonymousCannotReadUnits() throws Exception {
        mvc.perform(get("/api/don-vi-tinh"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void managerCanCreateUnit() throws Exception {
        when(service.createUnit("DVT001", "Hộp"))
            .thenReturn(new UnitView("DVT001", "Hộp"));
        mvc.perform(post("/api/don-vi-tinh").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"maDonViTinh\":\"DVT001\",\"tenDonViTinh\":\"Hộp\"}"))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.maDonViTinh").value("DVT001"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void accountantCannotCreateCategory() throws Exception {
        mvc.perform(post("/api/loai-san-pham").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"maLoai\":\"LSP001\",\"tenLoai\":\"Đồ khô\"}"))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void managerCannotWriteWithoutCsrf() throws Exception {
        mvc.perform(delete("/api/don-vi-tinh/DVT001"))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void invalidStorageRequirementIsRejected() throws Exception {
        mvc.perform(post("/api/loai-san-pham").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"maLoai\":\"LSP001\",\"tenLoai\":\"Đồ khô\",\"yeuCauBaoQuan\":\"Nóng\"}"))
            .andExpect(status().isUnprocessableEntity())
            .andExpect(jsonPath("$.fieldErrors[0].field").value("yeuCauBaoQuan"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void referencedCategoryCannotBeDeleted() throws Exception {
        org.mockito.Mockito.doThrow(new CatalogReferenceException(
            CatalogReferenceException.Kind.CONFLICT, "CATEGORY_IN_USE", "Đã được tham chiếu"))
            .when(service).deleteCategory(eq("LSP001"));
        mvc.perform(delete("/api/loai-san-pham/LSP001").with(csrf()))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.code").value("CATEGORY_IN_USE"));
    }
}
