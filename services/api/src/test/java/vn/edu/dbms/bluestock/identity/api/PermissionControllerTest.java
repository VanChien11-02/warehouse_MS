package vn.edu.dbms.bluestock.identity.api;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import vn.edu.dbms.bluestock.auth.infrastructure.SecurityConfig;
import vn.edu.dbms.bluestock.identity.application.PermissionService;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(PermissionController.class)
@Import({SecurityConfig.class, PermissionService.class})
class PermissionControllerTest {
    @Autowired private MockMvc mvc;
    @MockitoBean private UserDetailsService userDetailsService;

    @Test
    void anonymousCannotReadMatrix() throws Exception {
        mvc.perform(get("/api/quyen-han")).andExpect(status().isUnauthorized());
    }

    @ParameterizedTest
    @ValueSource(strings = {"QLKHO", "NVKHO", "KETOAN"})
    void otherRolesCannotReadMatrix(String role) throws Exception {
        mvc.perform(get("/api/quyen-han").with(user("user").roles(role)))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void adminReadsFourRolesAndCannotModifyMatrix() throws Exception {
        mvc.perform(get("/api/quyen-han"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.length()").value(4))
            .andExpect(jsonPath("$[0].role").value("ADMIN"))
            .andExpect(jsonPath("$[0].permissions[0].sua").value(true))
            .andExpect(jsonPath("$[0].permissions[0].xoaHoacHuy").value(false))
            .andExpect(jsonPath("$[0].permissions[1].xem").value(false))
            .andExpect(jsonPath("$[0].permissions[4].hoanTat").value(false))
            .andExpect(jsonPath("$[1].permissions[4].hoanTat").value(true))
            .andExpect(jsonPath("$[2].permissions[4].tao").value(true))
            .andExpect(jsonPath("$[2].permissions[6].xem").value(false))
            .andExpect(jsonPath("$[3].permissions[4].tao").value(false))
            .andExpect(jsonPath("$[3].permissions[10].xem").value(true));
        mvc.perform(post("/api/quyen-han").with(csrf())).andExpect(status().isForbidden());
    }
}
