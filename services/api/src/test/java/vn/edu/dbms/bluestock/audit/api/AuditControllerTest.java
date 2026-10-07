package vn.edu.dbms.bluestock.audit.api;

import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import vn.edu.dbms.bluestock.audit.application.AuditModels.AuditPage;
import vn.edu.dbms.bluestock.audit.application.AuditService;
import vn.edu.dbms.bluestock.auth.infrastructure.SecurityConfig;
import vn.edu.dbms.bluestock.platform.api.ApiExceptionHandler;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AuditController.class)
@Import({SecurityConfig.class, AuditExceptionHandler.class, ApiExceptionHandler.class})
class AuditControllerTest {
    @Autowired private MockMvc mvc;
    @MockitoBean private AuditService service;
    @MockitoBean private UserDetailsService userDetailsService;

    @Test
    @WithMockUser(authorities = "ROLE_ADMIN")
    void adminCanReadAudit() throws Exception {
        LocalDate date = LocalDate.of(2026, 10, 7);
        when(service.list(date, date, "TK0001", 0, 20))
            .thenReturn(new AuditPage(date, date, List.of(), 0, 20, 0, 0));
        mvc.perform(get("/api/audit").param("tuNgay", "2026-10-07")
                .param("denNgay", "2026-10-07").param("maTaiKhoan", "TK0001"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.items").isEmpty());
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void managerCannotReadAudit() throws Exception {
        mvc.perform(get("/api/audit").param("tuNgay", "2026-10-07")
                .param("denNgay", "2026-10-07"))
            .andExpect(status().isForbidden());
    }
}
