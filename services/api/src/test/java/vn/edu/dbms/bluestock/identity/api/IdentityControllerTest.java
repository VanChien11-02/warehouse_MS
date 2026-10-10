package vn.edu.dbms.bluestock.identity.api;

import java.time.LocalDate;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import vn.edu.dbms.bluestock.auth.infrastructure.AccountPrincipal;
import vn.edu.dbms.bluestock.auth.infrastructure.SecurityConfig;
import vn.edu.dbms.bluestock.identity.application.IdentityModels.AccountView;
import vn.edu.dbms.bluestock.identity.application.IdentityModels.EmployeeView;
import vn.edu.dbms.bluestock.identity.application.IdentityService;
import vn.edu.dbms.bluestock.platform.api.ApiExceptionHandler;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest({EmployeeController.class, AccountController.class})
@Import({SecurityConfig.class, IdentityExceptionHandler.class, ApiExceptionHandler.class})
class IdentityControllerTest {
    @Autowired private MockMvc mvc;
    @MockitoBean private IdentityService service;
    @MockitoBean private UserDetailsService userDetailsService;

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void staffCannotReadEmployeesOrAccounts() throws Exception {
        mvc.perform(get("/api/nhan-vien")).andExpect(status().isForbidden());
        mvc.perform(get("/api/tai-khoan")).andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLE_ADMIN")
    void adminCanCreateEmployee() throws Exception {
        when(service.createEmployee(eq("NV0002"), any(), eq("TK0001"))).thenReturn(employee());
        mvc.perform(post("/api/nhan-vien").with(csrf()).with(user(principal()))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"maNhanVien\":\"NV0002\",\"tenNhanVien\":\"Thủ kho\",\"ngayVaoLam\":\"2026-10-07\"}"))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.maNhanVien").value("NV0002"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_ADMIN")
    void adminCanCreateAccountWithoutReturningHash() throws Exception {
        when(service.createAccount("TK0002", "NV0002", "staff", "NVKHO", "strong-password-123", "TK0001"))
            .thenReturn(account());
        mvc.perform(post("/api/tai-khoan").with(csrf()).with(user(principal()))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"maTaiKhoan\":\"TK0002\",\"maNhanVien\":\"NV0002\",\"tenTaiKhoan\":\"staff\",\"role\":\"NVKHO\",\"matKhau\":\"strong-password-123\"}"))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.role").value("NVKHO"))
            .andExpect(jsonPath("$.matKhauHash").doesNotExist());
    }

    @Test
    void adminCanUpdateOwnAccountButCannotSkipCsrf() throws Exception {
        AccountPrincipal principal = new AccountPrincipal("TK0001", "NV0001", "Admin",
            "admin", "hash", "ADMIN", true);
        String body = "{\"tenTaiKhoan\":\"admin\",\"role\":\"ADMIN\",\"trangThai\":true}";
        mvc.perform(put("/api/tai-khoan/TK0001").with(user(principal))
                .contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().isForbidden());
        when(service.updateAccount("TK0001", "admin", "ADMIN", true, "TK0001"))
            .thenReturn(new AccountView("TK0001", "NV0001", "Admin", "admin", "ADMIN", true));
        mvc.perform(put("/api/tai-khoan/TK0001").with(user(principal)).with(csrf())
                .contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().isOk());
    }

    @Test
    @WithMockUser(authorities = "ROLE_ADMIN")
    void resetPasswordRequiresValidLength() throws Exception {
        mvc.perform(put("/api/tai-khoan/TK0002/mat-khau").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"matKhauMoi\":\"short\"}"))
            .andExpect(status().isUnprocessableEntity());
    }

    private static EmployeeView employee() {
        return new EmployeeView("NV0002", "Thủ kho", null, null, null,
            null, null, LocalDate.of(2026, 10, 7), true);
    }

    private static AccountView account() {
        return new AccountView("TK0002", "NV0002", "Thủ kho", "staff", "NVKHO", true);
    }

    private static AccountPrincipal principal() {
        return new AccountPrincipal("TK0001", "NV0001", "Admin",
            "admin", "hash", "ADMIN", true);
    }
}
