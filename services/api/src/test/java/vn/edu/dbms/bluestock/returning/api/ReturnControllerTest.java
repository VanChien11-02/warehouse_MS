package vn.edu.dbms.bluestock.returning.api;

import java.time.OffsetDateTime;
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
import vn.edu.dbms.bluestock.auth.infrastructure.AccountPrincipal;
import vn.edu.dbms.bluestock.auth.infrastructure.SecurityConfig;
import vn.edu.dbms.bluestock.platform.api.ApiExceptionHandler;
import vn.edu.dbms.bluestock.returning.application.ReturnModels.CompletionView;
import vn.edu.dbms.bluestock.returning.application.ReturnModels.ReturnView;
import vn.edu.dbms.bluestock.returning.application.ReturnService;

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

@WebMvcTest(ReturnController.class)
@Import({SecurityConfig.class, ReturnExceptionHandler.class, ApiExceptionHandler.class})
class ReturnControllerTest {
    @Autowired private MockMvc mvc;
    @MockitoBean private ReturnService service;
    @MockitoBean private UserDetailsService userDetailsService;

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void accountantCanReadReturn() throws Exception {
        when(service.get("TH0001")).thenReturn(returnDoc());
        mvc.perform(get("/api/phieu-tra-hang/TH0001"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.maPhieuXuat").value("PX0001"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void accountantCannotCancelReturn() throws Exception {
        mvc.perform(post("/api/phieu-tra-hang/TH0001/huy").with(csrf()))
            .andExpect(status().isForbidden());
    }

    @Test
    void staffCanCancelDraft() throws Exception {
        when(service.cancel("TH0001", "TK0001")).thenReturn(returnDoc());
        mvc.perform(post("/api/phieu-tra-hang/TH0001/huy")
                .with(csrf()).with(user(principal("NVKHO"))))
            .andExpect(status().isOk());
    }

    @Test
    void staffCanCreateDraft() throws Exception {
        when(service.create(eq("NV0001"), eq("PX0001"), eq(null), any()))
            .thenReturn(returnDoc());
        mvc.perform(post("/api/phieu-tra-hang").with(csrf()).with(user(principal("NVKHO")))
                .contentType(MediaType.APPLICATION_JSON).content(createBody()))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.trangThai").value("NHAP"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void staffCanUpdateButCannotComplete() throws Exception {
        when(service.update(eq("TH0001"), eq(null), any())).thenReturn(returnDoc());
        mvc.perform(put("/api/phieu-tra-hang/TH0001").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(createBody().replace("\"maPhieuXuat\":\"PX0001\",", "")))
            .andExpect(status().isOk());
        mvc.perform(post("/api/phieu-tra-hang/TH0001/hoan-tat").with(csrf()))
            .andExpect(status().isForbidden());
    }

    @Test
    void managerCanCompleteReturn() throws Exception {
        when(service.complete("TH0001", "TK0001")).thenReturn(new CompletionView("TH0001",
            "DA_HOAN_THANH", OffsetDateTime.parse("2026-10-07T00:00:00Z")));
        mvc.perform(post("/api/phieu-tra-hang/TH0001/hoan-tat")
                .with(csrf()).with(user(principal("QLKHO"))))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.trangThai").value("DA_HOAN_THANH"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void zeroReturnQuantityIsRejected() throws Exception {
        mvc.perform(post("/api/phieu-tra-hang").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(createBody().replace("\"soLuong\":2", "\"soLuong\":0")))
            .andExpect(status().isUnprocessableEntity());
    }

    private static AccountPrincipal principal(String role) {
        return new AccountPrincipal("TK0001", "NV0001", "Nhân viên", "staff",
            "hash", role, true);
    }

    private static ReturnView returnDoc() {
        return new ReturnView("TH0001", OffsetDateTime.parse("2026-10-07T00:00:00Z"),
            "PX0001", "NV0001", "NHAP", null, null, List.of());
    }

    private static String createBody() {
        return "{\"maPhieuXuat\":\"PX0001\",\"chiTiet\":[{\"maLo\":\"LO0001\",\"maViTri\":\"VT0001\",\"soLuong\":2,\"tinhTrang\":\"Tốt\"}]}";
    }
}
