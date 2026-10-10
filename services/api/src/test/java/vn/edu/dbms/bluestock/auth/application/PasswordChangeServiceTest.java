package vn.edu.dbms.bluestock.auth.application;

import java.util.List;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import vn.edu.dbms.bluestock.audit.application.AuditTrail;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class PasswordChangeServiceTest {
    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
    private final AuditTrail audit = mock(AuditTrail.class);
    private final PasswordChangeService service = new PasswordChangeService(jdbc, encoder, audit);

    @Test
    void currentPasswordMustMatchLatestHashBeforeUpdating() {
        when(jdbc.queryForList(anyString(), eq(String.class), eq("TK0001")))
            .thenReturn(List.of(encoder.encode("current-password")));
        assertThrows(BadCredentialsException.class,
            () -> service.change("TK0001", "wrong-password", "new-password-123"));
        verify(jdbc, never()).update(anyString(), anyString(), eq("TK0001"));
    }

    @Test
    void newPasswordIsStoredAsDifferentBcryptHash() {
        when(jdbc.queryForList(anyString(), eq(String.class), eq("TK0001")))
            .thenReturn(List.of(encoder.encode("current-password")));
        service.change("TK0001", "current-password", "new-password-123");
        ArgumentCaptor<String> hash = ArgumentCaptor.forClass(String.class);
        verify(jdbc).update(anyString(), hash.capture(), eq("TK0001"));
        assertFalse(hash.getValue().equals("new-password-123"));
        assertTrue(encoder.matches("new-password-123", hash.getValue()));
        verify(audit).record("TK0001", "PASSWORD_CHANGE", "TAI_KHOAN", "TK0001", null, null);
    }

    @Test
    void samePasswordIsRejected() {
        when(jdbc.queryForList(anyString(), eq(String.class), eq("TK0001")))
            .thenReturn(List.of(encoder.encode("current-password")));
        assertThrows(PasswordChangeException.class,
            () -> service.change("TK0001", "current-password", "current-password"));
        verify(jdbc, never()).update(anyString(), anyString(), eq("TK0001"));
    }
}
