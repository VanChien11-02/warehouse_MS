package vn.edu.dbms.bluestock.partner.api;

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
import vn.edu.dbms.bluestock.partner.application.PartnerModels.SupplierView;
import vn.edu.dbms.bluestock.partner.application.PartnerService;
import vn.edu.dbms.bluestock.platform.api.ApiExceptionHandler;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(SupplierController.class)
@Import({SecurityConfig.class, PartnerExceptionHandler.class, ApiExceptionHandler.class})
class SupplierControllerTest {
    @Autowired private MockMvc mvc;
    @MockitoBean private PartnerService service;
    @MockitoBean private UserDetailsService userDetailsService;

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void accountantCanReadSupplierProducts() throws Exception {
        when(service.supplierProducts("NCC001")).thenReturn(List.of("SP0001"));
        mvc.perform(get("/api/nha-cung-cap/NCC001/san-pham"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[0]").value("SP0001"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void managerCanCreateSupplierAndMapping() throws Exception {
        when(service.createSupplier("NCC001", "Nhà cung cấp A", null, null, null))
            .thenReturn(new SupplierView("NCC001", "Nhà cung cấp A", null, null, null));
        mvc.perform(post("/api/nha-cung-cap").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"maNhaCungCap\":\"NCC001\",\"tenNhaCungCap\":\"Nhà cung cấp A\"}"))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.maNhaCungCap").value("NCC001"));
        mvc.perform(post("/api/nha-cung-cap/NCC001/san-pham/SP0001").with(csrf()))
            .andExpect(status().isCreated());
        verify(service).addSupplierProduct("NCC001", "SP0001");
    }

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void staffCannotCreateMapping() throws Exception {
        mvc.perform(post("/api/nha-cung-cap/NCC001/san-pham/SP0001").with(csrf()))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLE_ADMIN")
    void invalidEmailIsRejected() throws Exception {
        mvc.perform(post("/api/nha-cung-cap").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"maNhaCungCap\":\"NCC001\",\"tenNhaCungCap\":\"A\",\"email\":\"invalid\"}"))
            .andExpect(status().isUnprocessableEntity())
            .andExpect(jsonPath("$.fieldErrors[0].field").value("email"));
    }
}
