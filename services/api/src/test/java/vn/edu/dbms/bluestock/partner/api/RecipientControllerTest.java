package vn.edu.dbms.bluestock.partner.api;

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
import vn.edu.dbms.bluestock.partner.application.PartnerModels.RecipientView;
import vn.edu.dbms.bluestock.partner.application.PartnerService;
import vn.edu.dbms.bluestock.platform.api.ApiExceptionHandler;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(RecipientController.class)
@Import({SecurityConfig.class, PartnerExceptionHandler.class, ApiExceptionHandler.class})
class RecipientControllerTest {
    @Autowired private MockMvc mvc;
    @MockitoBean private PartnerService service;
    @MockitoBean private UserDetailsService userDetailsService;

    @Test
    @WithMockUser(authorities = "ROLE_KETOAN")
    void accountantCanReadRecipientProducts() throws Exception {
        when(service.recipientProducts("DTN001")).thenReturn(List.of("SP0001"));
        mvc.perform(get("/api/doi-tac-nhan-hang/DTN001/san-pham"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[0]").value("SP0001"));
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void managerCanCreateRecipientAndMapping() throws Exception {
        when(service.createRecipient("DTN001", "Đại lý A", "Đại lý", null, null, null))
            .thenReturn(new RecipientView("DTN001", "Đại lý A", "Đại lý", null, null, null));
        mvc.perform(post("/api/doi-tac-nhan-hang").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"maDoiTacNhanHang\":\"DTN001\",\"tenDoiTac\":\"Đại lý A\",\"loaiDoiTac\":\"Đại lý\"}"))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.loaiDoiTac").value("Đại lý"));
        mvc.perform(post("/api/doi-tac-nhan-hang/DTN001/san-pham/SP0001").with(csrf()))
            .andExpect(status().isCreated());
        verify(service).addRecipientProduct("DTN001", "SP0001");
    }

    @Test
    @WithMockUser(authorities = "ROLE_NVKHO")
    void staffCannotCreateMapping() throws Exception {
        mvc.perform(post("/api/doi-tac-nhan-hang/DTN001/san-pham/SP0001").with(csrf()))
            .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(authorities = "ROLE_QLKHO")
    void missingTypeIsRejected() throws Exception {
        mvc.perform(post("/api/doi-tac-nhan-hang").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"maDoiTacNhanHang\":\"DTN001\",\"tenDoiTac\":\"Đại lý A\"}"))
            .andExpect(status().isUnprocessableEntity())
            .andExpect(jsonPath("$.fieldErrors[0].field").value("loaiDoiTac"));
    }
}
