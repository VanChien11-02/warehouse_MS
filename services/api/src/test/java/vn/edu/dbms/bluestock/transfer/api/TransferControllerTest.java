package vn.edu.dbms.bluestock.transfer.api;

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
import vn.edu.dbms.bluestock.transfer.application.TransferModels.CompletionView;
import vn.edu.dbms.bluestock.transfer.application.TransferModels.TransferView;
import vn.edu.dbms.bluestock.transfer.application.TransferService;

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

@WebMvcTest(TransferController.class)
@Import({SecurityConfig.class, TransferExceptionHandler.class, ApiExceptionHandler.class})
class TransferControllerTest {
    @Autowired private MockMvc mvc;
    @MockitoBean private TransferService service;
    @MockitoBean private UserDetailsService userDetailsService;

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void accountantCanReadTransfer() throws Exception {
        when(service.get("PC0001")).thenReturn(transfer());
        mvc.perform(get("/api/phieu-chuyen/PC0001"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.maPhieuChuyen").value("PC0001"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void accountantCannotCancelDraft() throws Exception {
        mvc.perform(post("/api/phieu-chuyen/PC0001/huy").with(csrf()))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void staffCanUpdateDraft() throws Exception {
        when(service.update(eq("PC0001"), eq(null), any())).thenReturn(transfer());
        mvc.perform(put("/api/phieu-chuyen/PC0001").with(csrf())
                .contentType(MediaType.APPLICATION_JSON).content(createBody()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.trangThai").value("NHAP"));
    }

    @Test
    void staffCanCreateDraft() throws Exception {
        when(service.create(eq("NV0001"), eq(null), any())).thenReturn(transfer());
        mvc.perform(post("/api/phieu-chuyen").with(csrf()).with(user(principal("NVKHO")))
                .contentType(MediaType.APPLICATION_JSON).content(createBody()))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.trangThai").value("NHAP"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void staffCannotCompleteTransfer() throws Exception {
        mvc.perform(post("/api/phieu-chuyen/PC0001/hoan-tat").with(csrf()))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void managerCanCompleteTransfer() throws Exception {
        when(service.complete("PC0001")).thenReturn(new CompletionView("PC0001",
            "DA_HOAN_THANH", OffsetDateTime.parse("2026-10-07T00:00:00Z")));
        mvc.perform(post("/api/phieu-chuyen/PC0001/hoan-tat").with(csrf()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.trangThai").value("DA_HOAN_THANH"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void zeroQuantityIsRejected() throws Exception {
        mvc.perform(post("/api/phieu-chuyen").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(createBody().replace("\"soLuong\":2", "\"soLuong\":0")))
            .andExpect(status().isUnprocessableEntity());
    }

    private static AccountPrincipal principal(String role) {
        return new AccountPrincipal("TK0001", "NV0001", "Nhân viên", "staff",
            "hash", role, true);
    }

    private static TransferView transfer() {
        return new TransferView("PC0001", OffsetDateTime.parse("2026-10-07T00:00:00Z"),
            "NV0001", "NHAP", null, null, List.of());
    }

    private static String createBody() {
        return "{\"chiTiet\":[{\"maLo\":\"LO0001\",\"maViTriNguon\":\"VT0001\",\"maViTriDich\":\"VT0002\",\"soLuong\":2}]}";
    }
}
