package vn.edu.dbms.bluestock.outbound.api;

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
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.CompletionView;
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.FefoSuggestion;
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.OutboundView;
import vn.edu.dbms.bluestock.outbound.application.OutboundService;
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

@WebMvcTest(OutboundController.class)
@Import({SecurityConfig.class, OutboundExceptionHandler.class, ApiExceptionHandler.class})
class OutboundControllerTest {
    @Autowired
    private MockMvc mvc;

    @MockitoBean
    private OutboundService service;

    @MockitoBean
    private UserDetailsService userDetailsService;

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void accountantCanReadOutbound() throws Exception {
        when(service.get("PX0001")).thenReturn(outbound());
        mvc.perform(get("/api/phieu-xuat/PX0001"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.maPhieuXuat").value("PX0001"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void accountantCannotCancelDraft() throws Exception {
        mvc.perform(post("/api/phieu-xuat/PX0001/huy").with(csrf()))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void warehouseStaffCanUpdateDraft() throws Exception {
        when(service.update(eq("PX0001"), eq("DT0001"), eq(null), any()))
            .thenReturn(outbound());
        mvc.perform(put("/api/phieu-xuat/PX0001").with(csrf())
                .contentType(MediaType.APPLICATION_JSON).content(createBody()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.trangThai").value("NHAP"));
    }

    @Test
    void anonymousCannotReadOutbound() throws Exception {
        mvc.perform(get("/api/phieu-xuat/PX0001"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void warehouseStaffCanCreateDraft() throws Exception {
        when(service.create(eq("DT0001"), eq("NV0001"), eq(null), any()))
            .thenReturn(outbound());
        mvc.perform(post("/api/phieu-xuat").with(csrf()).with(user(principal("NVKHO")))
                .contentType(MediaType.APPLICATION_JSON)
                .content(createBody()))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.trangThai").value("NHAP"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_ADMIN")
    void adminCannotCreateDraft() throws Exception {
        mvc.perform(post("/api/phieu-xuat").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(createBody()))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void warehouseStaffCannotCompleteOutbound() throws Exception {
        mvc.perform(post("/api/phieu-xuat/PX0001/hoan-tat").with(csrf()))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void managerCanCompleteOutbound() throws Exception {
        when(service.complete("PX0001", "TK0001")).thenReturn(new CompletionView("PX0001",
            "DA_HOAN_THANH", OffsetDateTime.parse("2026-10-07T00:00:00Z")));
        mvc.perform(post("/api/phieu-xuat/PX0001/hoan-tat").with(csrf())
                .with(user(principal("QLKHO"))))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.trangThai").value("DA_HOAN_THANH"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void zeroOutboundQuantityIsRejected() throws Exception {
        mvc.perform(post("/api/phieu-xuat").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(createBody().replace("\"soLuong\":2", "\"soLuong\":0")))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void warehouseStaffCanRequestFefoSuggestion() throws Exception {
        when(service.suggest("PX0001", "SP0001", 5, null))
            .thenReturn(new FefoSuggestion("PX0001", "SP0001", 5, 0, List.of()));
        mvc.perform(get("/api/phieu-xuat/PX0001/goi-y-fefo")
                .param("maSanPham", "SP0001").param("soLuong", "5"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.soLuongThieu").value(0));
    }

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void accountantCannotRequestFefoSuggestion() throws Exception {
        mvc.perform(get("/api/phieu-xuat/PX0001/goi-y-fefo")
                .param("maSanPham", "SP0001").param("soLuong", "5"))
            .andExpect(status().isForbidden());
    }

    private static AccountPrincipal principal(String role) {
        return new AccountPrincipal("TK0001", "NV0001", "Nhân viên", "staff",
            "hash", role, true);
    }

    private static OutboundView outbound() {
        return new OutboundView("PX0001", OffsetDateTime.parse("2026-10-07T00:00:00Z"),
            "DT0001", "Đối tác", "NV0001", "NHAP", null, null, List.of(
                new vn.edu.dbms.bluestock.outbound.application.OutboundModels.LineView(
                    "LO0001", "VT0001", "SP0001", "Sản phẩm", null, 2,
                    new BigDecimal("1.0000"))));
    }

    private static String createBody() {
        return "{\"maDoiTacNhanHang\":\"DT0001\",\"chiTiet\":[{\"maLo\":\"LO0001\",\"maViTri\":\"VT0001\",\"soLuong\":2,\"donGiaXuat\":1.0000}]}";
    }
}
