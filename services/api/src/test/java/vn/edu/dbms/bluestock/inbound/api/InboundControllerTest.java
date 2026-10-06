package vn.edu.dbms.bluestock.inbound.api;

import java.math.BigDecimal;
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
import vn.edu.dbms.bluestock.inbound.application.InboundModels.CompletionView;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.InboundView;
import vn.edu.dbms.bluestock.inbound.application.InboundService;
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

@WebMvcTest(InboundController.class)
@Import({SecurityConfig.class, InboundExceptionHandler.class, ApiExceptionHandler.class})
class InboundControllerTest {
    @Autowired
    private MockMvc mvc;

    @MockitoBean
    private InboundService service;

    @MockitoBean
    private UserDetailsService userDetailsService;

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void accountantCanReadInbound() throws Exception {
        when(service.get("PN0001")).thenReturn(inbound());
        mvc.perform(get("/api/phieu-nhap/PN0001"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.maPhieuNhap").value("PN0001"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void accountantCannotCancelDraft() throws Exception {
        mvc.perform(post("/api/phieu-nhap/PN0001/huy").with(csrf()))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void warehouseStaffCanUpdateDraft() throws Exception {
        when(service.update(eq("PN0001"), eq("NCC001"), eq(null), any()))
            .thenReturn(inbound());
        mvc.perform(put("/api/phieu-nhap/PN0001").with(csrf())
                .contentType(MediaType.APPLICATION_JSON).content(createBody()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.trangThai").value("NHAP"));
    }

    @Test
    void anonymousCannotReadInbound() throws Exception {
        mvc.perform(get("/api/phieu-nhap/PN0001"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void warehouseStaffCanCreateDraft() throws Exception {
        when(service.create(eq("NCC001"), eq("NV0001"), eq(null), any()))
            .thenReturn(inbound());
        mvc.perform(post("/api/phieu-nhap").with(csrf()).with(user(principal("NVKHO")))
                .contentType(MediaType.APPLICATION_JSON)
                .content(createBody()))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.trangThai").value("NHAP"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_ADMIN")
    void adminCannotCreateDraft() throws Exception {
        mvc.perform(post("/api/phieu-nhap").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(createBody()))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void warehouseStaffCannotCompleteInbound() throws Exception {
        mvc.perform(post("/api/phieu-nhap/PN0001/hoan-tat").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(completionBody()))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void managerCanCompleteInbound() throws Exception {
        when(service.complete(eq("PN0001"), any())).thenReturn(new CompletionView(
            "PN0001", "DA_HOAN_THANH", OffsetDateTime.parse("2026-10-07T00:00:00Z")));
        mvc.perform(post("/api/phieu-nhap/PN0001/hoan-tat").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(completionBody()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.trangThai").value("DA_HOAN_THANH"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void zeroAllocationIsRejected() throws Exception {
        mvc.perform(post("/api/phieu-nhap/PN0001/hoan-tat").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(completionBody().replace("\"soLuong\":2", "\"soLuong\":0")))
            .andExpect(status().isUnprocessableEntity());
    }

    private static AccountPrincipal principal(String role) {
        return new AccountPrincipal("TK0001", "NV0001", "Nhân viên", "staff",
            "hash", role, true);
    }

    private static InboundView inbound() {
        return new InboundView("PN0001", OffsetDateTime.parse("2026-10-07T00:00:00Z"),
            "NCC001", "Nhà cung cấp", "NV0001", "NHAP", null, null, List.of(
                new vn.edu.dbms.bluestock.inbound.application.InboundModels.LineView(
                    "SP0001", "Sản phẩm", 2, new BigDecimal("1.0000"))));
    }

    private static String createBody() {
        return "{\"maNhaCungCap\":\"NCC001\",\"chiTiet\":[{\"maSanPham\":\"SP0001\",\"soLuong\":2,\"donGiaNhap\":1.0000}]}";
    }

    private static String completionBody() {
        return "{\"phanBo\":[{\"maSanPham\":\"SP0001\",\"maViTri\":\"VT0001\",\"soLuong\":2}]}";
    }
}
