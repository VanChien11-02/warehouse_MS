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
import vn.edu.dbms.bluestock.inbound.application.InboundException;
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
    void managerAndAccountantCanReadLotHistoryWithFilters() throws Exception {
        var item = new vn.edu.dbms.bluestock.inbound.application.InboundModels.HistoryItem(
            "PN0001", OffsetDateTime.parse("2026-10-25T00:00:00Z"), "NCC001", "SP0001", "Mì hộp",
            "DVT001", "LO0001", null, null, 6, new BigDecimal("12500.0000"), new BigDecimal("75000.0000"));
        when(service.history(0, 20, "PN0001", "SP0001", "NCC001", java.time.LocalDate.parse("2026-10-25"), null))
            .thenReturn(new vn.edu.dbms.bluestock.inbound.application.InboundModels.HistoryPage(List.of(item), 0, 20, 1, 1));
        for (String role : List.of("QLKHO", "KETOAN")) {
            mvc.perform(get("/api/phieu-nhap/lich-su").with(user(principal(role)))
                    .param("maPhieuNhap", "PN0001").param("maSanPham", "SP0001")
                    .param("maNhaCungCap", "NCC001").param("tuNgay", "2026-10-25"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].maLo").value("LO0001"))
                .andExpect(jsonPath("$.items[0].giaTriNhap").value(75000))
                .andExpect(jsonPath("$.items[0].ngayHoanTat").value("2026-10-25T00:00:00Z"));
        }
    }

    @Test
    void staffAndAdminCannotReadLotHistory() throws Exception {
        for (String role : List.of("NVKHO", "ADMIN")) {
            mvc.perform(get("/api/phieu-nhap/lich-su").with(user(principal(role))))
                .andExpect(status().isForbidden());
        }
        org.mockito.Mockito.verifyNoInteractions(service);
    }

    @Test
    void anonymousCannotReadLotHistory() throws Exception {
        mvc.perform(get("/api/phieu-nhap/lich-su")).andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void historyRejectsMalformedDate() throws Exception {
        mvc.perform(get("/api/phieu-nhap/lich-su").param("tuNgay", "sai-ngay"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.code").value("INVALID_PARAMETER"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void accountantCannotCancelDraft() throws Exception {
        mvc.perform(post("/api/phieu-nhap/PN0001/huy").with(csrf()))
            .andExpect(status().isForbidden());
    }

    @Test
    void warehouseStaffCanCancelDraft() throws Exception {
        when(service.cancel("PN0001", "TK0001")).thenReturn(inbound());
        mvc.perform(post("/api/phieu-nhap/PN0001/huy")
                .with(csrf()).with(user(principal("NVKHO"))))
            .andExpect(status().isOk());
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
        when(service.complete(eq("PN0001"), any(), eq("TK0001"))).thenReturn(new CompletionView(
            "PN0001", "DA_HOAN_THANH", OffsetDateTime.parse("2026-10-07T00:00:00Z")));
        mvc.perform(post("/api/phieu-nhap/PN0001/hoan-tat").with(csrf())
                .with(user(principal("QLKHO")))
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

    @Test
    void completionDisplaysLotTriggerRejectionAsBusinessValidation() throws Exception {
        when(service.complete(eq("PN0001"), any(), eq("TK0001"))).thenThrow(
            new InboundException(InboundException.Kind.VALIDATION, "ALLOCATION_EXCEEDS_LINE",
                "Tổng số lượng phân bổ vượt số lượng nhập."));
        mvc.perform(post("/api/phieu-nhap/PN0001/hoan-tat")
                .with(csrf()).with(user(principal("QLKHO")))
                .contentType(MediaType.APPLICATION_JSON).content("""
                    {"phanBo":[{"maSanPham":"SP0001","maViTri":"VT0001","soLuong":6},
                                {"maSanPham":"SP0001","maViTri":"VT0002","soLuong":5}]}
                    """))
            .andExpect(status().isUnprocessableEntity())
            .andExpect(jsonPath("$.code").value("ALLOCATION_EXCEEDS_LINE"))
            .andExpect(jsonPath("$.message").value("Tổng số lượng phân bổ vượt số lượng nhập."));
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void removedPracticeEndpointIsNoLongerAccessible() throws Exception {
        mvc.perform(post("/api/thuc-hanh/trigger-nhap").with(csrf())
                .contentType(MediaType.APPLICATION_JSON).content("{}"))
            .andExpect(status().isForbidden());
        org.mockito.Mockito.verifyNoInteractions(service);
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
