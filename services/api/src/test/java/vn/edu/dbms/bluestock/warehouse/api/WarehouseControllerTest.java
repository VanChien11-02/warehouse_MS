package vn.edu.dbms.bluestock.warehouse.api;

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
import vn.edu.dbms.bluestock.auth.infrastructure.SecurityConfig;
import vn.edu.dbms.bluestock.platform.api.ApiExceptionHandler;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseException;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseModels.AreaView;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseModels.Page;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseModels.PositionView;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseModels.WarehouseView;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseService;

import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest({WarehouseController.class, AreaController.class, PositionController.class})
@Import({SecurityConfig.class, WarehouseExceptionHandler.class, ApiExceptionHandler.class})
class WarehouseControllerTest {
    @Autowired
    private MockMvc mvc;

    @MockitoBean
    private WarehouseService service;

    @MockitoBean
    private UserDetailsService userDetailsService;

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void warehouseStaffCanReadAreaByWarehouse() throws Exception {
        when(service.areas(0, 20, "KHO001", null)).thenReturn(new Page<>(
            List.of(new AreaView("KV0001", "KHO001", "Kho chính", "Khu khô", "Khô")),
            0, 20, 1, 1));
        mvc.perform(get("/api/khu-vuc").param("maKho", "KHO001"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.items[0].maKhuVuc").value("KV0001"));
    }

    @Test
    void anonymousCannotReadWarehouse() throws Exception {
        mvc.perform(get("/api/kho"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void managerCanCreateWarehouse() throws Exception {
        when(service.createWarehouse("KHO001", "Kho chính", null))
            .thenReturn(new WarehouseView("KHO001", "Kho chính", null));
        mvc.perform(post("/api/kho").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"maKho\":\"KHO001\",\"tenKho\":\"Kho chính\"}"))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.maKho").value("KHO001"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void accountantCannotCreateArea() throws Exception {
        mvc.perform(post("/api/khu-vuc").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(validArea()))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLE_ADMIN")
    void invalidAreaTypeIsRejected() throws Exception {
        mvc.perform(post("/api/khu-vuc").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(validArea().replace("Khô", "Nóng")))
            .andExpect(status().isUnprocessableEntity())
            .andExpect(jsonPath("$.fieldErrors[0].field").value("loaiKhuVuc"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_ADMIN")
    void missingWarehouseReferenceIsRejected() throws Exception {
        when(service.createArea("KV0001", "KHO999", "Khu khô", "Khô"))
            .thenThrow(new WarehouseException(WarehouseException.Kind.VALIDATION,
                "INVALID_WAREHOUSE", "Kho không tồn tại"));
        mvc.perform(post("/api/khu-vuc").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(validArea().replace("KHO001", "KHO999")))
            .andExpect(status().isUnprocessableEntity())
            .andExpect(jsonPath("$.code").value("INVALID_WAREHOUSE"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void managerCanCreatePosition() throws Exception {
        when(service.createPosition("VT0001", "KV0001", "Kệ 1", 100, "Lưu trữ"))
            .thenReturn(new PositionView("VT0001", "KV0001", "Khu khô", "KHO001",
                "Kho chính", "Kệ 1", 100, "Lưu trữ", "Khô"));
        mvc.perform(post("/api/vi-tri").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(validPosition()))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.sucChua").value(100));
    }

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void warehouseStaffCannotCreatePosition() throws Exception {
        mvc.perform(post("/api/vi-tri").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(validPosition()))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLE_ADMIN")
    void negativePositionCapacityIsRejected() throws Exception {
        mvc.perform(post("/api/vi-tri").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(validPosition().replace("100", "-1")))
            .andExpect(status().isUnprocessableEntity())
            .andExpect(jsonPath("$.fieldErrors[0].field").value("sucChua"));
    }

    private static String validArea() {
        return "{\"maKhuVuc\":\"KV0001\",\"maKho\":\"KHO001\",\"tenKhuVuc\":\"Khu khô\",\"loaiKhuVuc\":\"Khô\"}";
    }

    private static String validPosition() {
        return "{\"maViTri\":\"VT0001\",\"maKhuVuc\":\"KV0001\",\"tenViTri\":\"Kệ 1\",\"sucChua\":100,\"loaiViTri\":\"Lưu trữ\"}";
    }
}
