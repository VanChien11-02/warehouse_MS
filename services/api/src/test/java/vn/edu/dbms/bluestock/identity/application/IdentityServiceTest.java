package vn.edu.dbms.bluestock.identity.application;

import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import vn.edu.dbms.bluestock.identity.application.IdentityModels.AccountView;
import vn.edu.dbms.bluestock.identity.infrastructure.IdentityJdbcRepository;
import vn.edu.dbms.bluestock.audit.application.AuditTrail;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class IdentityServiceTest {
    private final IdentityJdbcRepository repository = mock(IdentityJdbcRepository.class);
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
    private final AuditTrail audit = mock(AuditTrail.class);
    private final IdentityService service = new IdentityService(repository, encoder, audit);

    @Test
    void creatingAccountStoresOnlyHash() {
        when(repository.lockedEmployeeActive("NV0002")).thenReturn(Optional.of(true));
        when(repository.account("TK0002")).thenReturn(Optional.of(account()));
        service.createAccount("TK0002", "NV0002", "staff", "NVKHO", "strong-password-123", "TK0001");
        ArgumentCaptor<String> hash = ArgumentCaptor.forClass(String.class);
        verify(repository).insertAccount(eq("TK0002"), eq("NV0002"), eq("staff"),
            eq("NVKHO"), hash.capture());
        assertTrue(encoder.matches("strong-password-123", hash.getValue()));
        verify(audit).record("TK0001", "CREATE", "TAI_KHOAN", "TK0002", null, account());
    }

    @Test
    void adminCannotDisableOwnAccount() {
        when(repository.lockedAccount("TK0001")).thenReturn(Optional.of(
            new AccountView("TK0001", "NV0001", "Admin", "admin", "ADMIN", true)));
        IdentityException error = assertThrows(IdentityException.class,
            () -> service.updateAccount("TK0001", "admin", "ADMIN", false, "TK0001"));
        assertEquals("SELF_ROLE_CHANGE_FORBIDDEN", error.code());
        verify(repository, never()).updateAccount(anyString(), anyString(), anyString(), eq(false));
    }

    @Test
    void inactiveEmployeeCannotReceiveAccount() {
        when(repository.lockedEmployeeActive("NV0002")).thenReturn(Optional.of(false));
        IdentityException error = assertThrows(IdentityException.class,
            () -> service.createAccount("TK0002", "NV0002", "staff", "NVKHO", "strong-password-123", "TK0001"));
        assertEquals("EMPLOYEE_INACTIVE", error.code());
    }

    private static AccountView account() {
        return new AccountView("TK0002", "NV0002", "Thủ kho", "staff", "NVKHO", true);
    }
}
