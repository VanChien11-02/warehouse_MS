package vn.edu.dbms.bluestock.auth.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockHttpSession;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import vn.edu.dbms.bluestock.auth.application.AuthApplicationService;
import vn.edu.dbms.bluestock.auth.application.PasswordChangeService;
import vn.edu.dbms.bluestock.auth.infrastructure.AccountPrincipal;
import vn.edu.dbms.bluestock.auth.infrastructure.SecurityConfig;
import vn.edu.dbms.bluestock.platform.api.ApiExceptionHandler;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AuthController.class)
@Import({SecurityConfig.class, AuthApplicationService.class, ApiExceptionHandler.class})
class AuthControllerTest {
    @Autowired
    private MockMvc mvc;

    @Autowired
    private ObjectMapper json;

    @Autowired
    private PasswordEncoder encoder;

    @MockitoBean
    private UserDetailsService userDetailsService;

    @MockitoBean
    private PasswordChangeService passwordChangeService;

    @Test
    void sessionLoginAndLogoutRequireCsrf() throws Exception {
        String password = UUID.randomUUID().toString();
        when(userDetailsService.loadUserByUsername("manager"))
            .thenReturn(new AccountPrincipal("TK0001", "NV0001", "Quản lý kiểm thử",
                "manager", encoder.encode(password), "QLKHO", true));

        var csrfResult = mvc.perform(get("/api/auth/csrf"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.headerName").value("X-CSRF-TOKEN"))
            .andReturn();
        String token = json.readTree(csrfResult.getResponse().getContentAsString())
            .get("token").asText();
        var session = (MockHttpSession) csrfResult.getRequest().getSession(false);

        mvc.perform(post("/api/auth/dang-nhap").session(session)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsString(Map.of("tenTaiKhoan", "manager", "matKhau", password))))
            .andExpect(status().isForbidden());

        mvc.perform(post("/api/auth/dang-nhap").session(session)
                .header("X-CSRF-TOKEN", token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsString(Map.of("tenTaiKhoan", "manager", "matKhau", password))))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.role").value("QLKHO"))
            .andExpect(jsonPath("$.maNhanVien").value("NV0001"))
            .andExpect(jsonPath("$.password").doesNotExist());

        mvc.perform(get("/api/auth/me").session(session))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.tenTaiKhoan").value("manager"));

        mvc.perform(get("/api/private").session(session))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.code").value("FORBIDDEN"));

        mvc.perform(post("/api/auth/dang-xuat").session(session)
                .header("X-CSRF-TOKEN", token))
            .andExpect(status().isNoContent());

        mvc.perform(get("/api/auth/me"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void invalidCredentialsReturnGenericError() throws Exception {
        String password = UUID.randomUUID().toString();
        when(userDetailsService.loadUserByUsername("manager"))
            .thenReturn(new AccountPrincipal("TK0001", "NV0001", "Quản lý kiểm thử",
                "manager", encoder.encode(password), "QLKHO", true));
        var csrfResult = mvc.perform(get("/api/auth/csrf")).andReturn();
        String token = json.readTree(csrfResult.getResponse().getContentAsString())
            .get("token").asText();
        var session = (MockHttpSession) csrfResult.getRequest().getSession(false);

        mvc.perform(post("/api/auth/dang-nhap").session(session)
                .header("X-CSRF-TOKEN", token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsString(Map.of("tenTaiKhoan", "manager",
                    "matKhau", UUID.randomUUID().toString()))))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.code").value("INVALID_CREDENTIALS"));
    }

    @Test
    void configuredFrontendOriginCanSendCredentials() throws Exception {
        mvc.perform(options("/api/auth/dang-nhap")
                .header("Origin", "http://127.0.0.1:5174")
                .header("Access-Control-Request-Method", "POST"))
            .andExpect(status().isOk())
            .andExpect(result -> {
                String origin = result.getResponse().getHeader("Access-Control-Allow-Origin");
                String credentials = result.getResponse().getHeader("Access-Control-Allow-Credentials");
                org.junit.jupiter.api.Assertions.assertEquals("http://127.0.0.1:5174", origin);
                org.junit.jupiter.api.Assertions.assertEquals("true", credentials);
            });
    }

    @Test
    void authenticatedUserCanChangePasswordWithCsrf() throws Exception {
        var principal = new AccountPrincipal("TK0001", "NV0001", "Nhân viên",
            "staff", "hash", "NVKHO", true);
        String body = "{\"matKhauCu\":\"old-password\",\"matKhauMoi\":\"new-password-123\"}";
        mvc.perform(put("/api/auth/doi-mat-khau").with(user(principal))
                .contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().isForbidden());
        mvc.perform(put("/api/auth/doi-mat-khau").with(user(principal)).with(csrf())
                .contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().isNoContent());
        org.mockito.Mockito.verify(passwordChangeService)
            .change("TK0001", "old-password", "new-password-123");
    }
}
