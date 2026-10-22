package vn.edu.dbms.bluestock.accounting.api;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import vn.edu.dbms.bluestock.accounting.application.ReconciliationModels.ReconciliationView;
import vn.edu.dbms.bluestock.accounting.application.ReconciliationService;
import vn.edu.dbms.bluestock.auth.infrastructure.AccountPrincipal;
import vn.edu.dbms.bluestock.auth.infrastructure.SecurityConfig;

import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ReconciliationController.class)
@Import({SecurityConfig.class, ReconciliationExceptionHandler.class})
class ReconciliationControllerTest {
    @Autowired private MockMvc mvc;
    @MockitoBean private ReconciliationService service;
    @MockitoBean private UserDetailsService userDetailsService;

    @Test
    @WithMockUser(roles = "ADMIN")
    void adminCannotReadReconciliation() throws Exception {
        mvc.perform(get("/api/doi-soat-gia-tri/NHAP/PN0001"))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "NVKHO")
    void staffCannotReadReconciliation() throws Exception {
        mvc.perform(get("/api/doi-soat-gia-tri/NHAP/PN0001"))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "QLKHO")
    void managerCanReadButCannotReconcile() throws Exception {
        when(service.get("NHAP", "PN0001")).thenReturn(view());
        mvc.perform(get("/api/doi-soat-gia-tri/NHAP/PN0001"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.trangThai").value("KHOP"));
        mvc.perform(post("/api/doi-soat-gia-tri/NHAP/PN0001").with(csrf())
                .contentType(MediaType.APPLICATION_JSON).content("{\"giaTriDoiSoat\":20}"))
            .andExpect(status().isForbidden());
    }

    @Test
    void accountantCanReconcileWithCsrf() throws Exception {
        when(service.reconcile("NHAP", "PN0001", new BigDecimal("20"), null, "TK0004"))
            .thenReturn(view());
        mvc.perform(post("/api/doi-soat-gia-tri/NHAP/PN0001").with(csrf())
                .with(user(new AccountPrincipal("TK0004", "NV0004", "Kế toán", "ketoan",
                    "hash", "KETOAN", true)))
                .contentType(MediaType.APPLICATION_JSON).content("{\"giaTriDoiSoat\":20}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.maTaiKhoanKeToan").value("TK0004"));
    }

    private static ReconciliationView view() {
        return new ReconciliationView("NHAP", "PN0001", new BigDecimal("20"),
            new BigDecimal("20"), BigDecimal.ZERO, "KHOP", null, "TK0004",
            OffsetDateTime.parse("2026-10-22T00:00:00Z"));
    }
}
