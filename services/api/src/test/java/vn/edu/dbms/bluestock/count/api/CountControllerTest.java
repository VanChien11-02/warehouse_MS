package vn.edu.dbms.bluestock.count.api;

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
import vn.edu.dbms.bluestock.count.application.CountModels.CompletionView;
import vn.edu.dbms.bluestock.count.application.CountModels.CountView;
import vn.edu.dbms.bluestock.count.application.CountService;
import vn.edu.dbms.bluestock.platform.api.ApiExceptionHandler;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(CountController.class)
@Import({SecurityConfig.class, CountExceptionHandler.class, ApiExceptionHandler.class})
class CountControllerTest {
    @Autowired private MockMvc mvc;
    @MockitoBean private CountService service;
    @MockitoBean private UserDetailsService userDetailsService;

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void accountantCanReadCount() throws Exception {
        when(service.get("KK0001")).thenReturn(count());
        mvc.perform(get("/api/phieu-kiem-ke/KK0001"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.maViTri").value("VT0001"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void accountantCannotEnterActual() throws Exception {
        mvc.perform(put("/api/phieu-kiem-ke/KK0001/chi-tiet/LO0001").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"soLuongThucTe\":4}"))
            .andExpect(status().isForbidden());
    }

    @Test
    void staffCanCreateSnapshot() throws Exception {
        when(service.create(eq("NV0001"), eq("VT0001"), eq(null))).thenReturn(count());
        mvc.perform(post("/api/phieu-kiem-ke").with(csrf()).with(user(principal("NVKHO")))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"maViTri\":\"VT0001\"}"))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.chiTiet[0].soLuongHeThong").value(6));
    }

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void staffCanEnterActualButCannotComplete() throws Exception {
        when(service.setActual("KK0001", "LO0001", 4, "Hao hụt")).thenReturn(count());
        mvc.perform(put("/api/phieu-kiem-ke/KK0001/chi-tiet/LO0001").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"soLuongThucTe\":4,\"lyDoChenhLech\":\"Hao hụt\"}"))
            .andExpect(status().isOk());
        mvc.perform(post("/api/phieu-kiem-ke/KK0001/hoan-tat").with(csrf()))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void managerCanComplete() throws Exception {
        when(service.complete("KK0001", "TK0001")).thenReturn(new CompletionView("KK0001",
            "DA_HOAN_THANH", OffsetDateTime.parse("2026-10-07T00:00:00Z")));
        mvc.perform(post("/api/phieu-kiem-ke/KK0001/hoan-tat").with(csrf())
                .with(user(principal("QLKHO"))))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.trangThai").value("DA_HOAN_THANH"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void negativeActualIsRejected() throws Exception {
        mvc.perform(put("/api/phieu-kiem-ke/KK0001/chi-tiet/LO0001").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"soLuongThucTe\":-1}"))
            .andExpect(status().isUnprocessableEntity());
    }

    private static AccountPrincipal principal(String role) {
        return new AccountPrincipal("TK0001", "NV0001", "Nhân viên", "staff",
            "hash", role, true);
    }

    private static CountView count() {
        return new CountView("KK0001", OffsetDateTime.parse("2026-10-07T00:00:00Z"),
            "NV0001", "VT0001", "NHAP", null, null,
            List.of(new vn.edu.dbms.bluestock.count.application.CountModels.LineView(
                "LO0001", "SP0001", "Sản phẩm", 6, null, null)));
    }
}
