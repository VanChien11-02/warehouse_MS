package vn.edu.dbms.bluestock.reporting.api;

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
import vn.edu.dbms.bluestock.auth.infrastructure.SecurityConfig;
import vn.edu.dbms.bluestock.platform.api.ApiExceptionHandler;
import vn.edu.dbms.bluestock.reporting.application.ReportingModels.MovementReportPage;
import vn.edu.dbms.bluestock.reporting.application.ReportingModels.CountDiscrepancyPage;
import vn.edu.dbms.bluestock.reporting.application.ReportingModels.ExpiringLotPage;
import vn.edu.dbms.bluestock.reporting.application.ReportingService;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ReportingController.class)
@Import({SecurityConfig.class, ReportingExceptionHandler.class, ApiExceptionHandler.class})
class ReportingControllerTest {
    @Autowired private MockMvc mvc;
    @MockitoBean private ReportingService service;
    @MockitoBean private UserDetailsService userDetailsService;

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void accountantCanReadMovementReport() throws Exception {
        LocalDate date = LocalDate.of(2026, 10, 7);
        when(service.movementReport(date, date, null, null, 0, 20))
            .thenReturn(new MovementReportPage(date, date, List.of(), 0, 20, 0, 0));
        mvc.perform(get("/api/bao-cao/nhap-xuat")
                .param("tuNgay", "2026-10-07").param("denNgay", "2026-10-07"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.tuNgay").value("2026-10-07"))
            .andExpect(jsonPath("$.items").isEmpty());
    }

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void warehouseStaffCannotReadValuation() throws Exception {
        mvc.perform(get("/api/bao-cao/nhap-xuat")
                .param("tuNgay", "2026-10-07").param("denNgay", "2026-10-07"))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void invalidDateFormatIsRejected() throws Exception {
        mvc.perform(get("/api/bao-cao/nhap-xuat")
                .param("tuNgay", "07-10-2026").param("denNgay", "2026-10-07"))
            .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void accountantCanReadCountDiscrepancies() throws Exception {
        LocalDate date = LocalDate.of(2026, 10, 7);
        when(service.countDiscrepancies(date, date, null, "VT0001", 0, 20))
            .thenReturn(new CountDiscrepancyPage(date, date, List.of(), 0, 20, 0, 0));
        mvc.perform(get("/api/bao-cao/chenh-lech-kiem-ke")
                .param("tuNgay", "2026-10-07").param("denNgay", "2026-10-07")
                .param("maViTri", "VT0001"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.items").isEmpty());
    }

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void warehouseStaffCannotReadCountDiscrepancies() throws Exception {
        mvc.perform(get("/api/bao-cao/chenh-lech-kiem-ke")
                .param("tuNgay", "2026-10-07").param("denNgay", "2026-10-07"))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void warehouseStaffCannotReadExpiringLots() throws Exception {
        mvc.perform(get("/api/bao-cao/lo-sap-het-han")
                .param("soNgay", "7").param("maKho", "KHO001"))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void accountantCannotReadOperationalExpiryReport() throws Exception {
        mvc.perform(get("/api/bao-cao/lo-sap-het-han"))
            .andExpect(status().isForbidden());
    }
}
