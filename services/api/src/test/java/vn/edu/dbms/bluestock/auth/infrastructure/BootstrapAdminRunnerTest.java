package vn.edu.dbms.bluestock.auth.infrastructure;

import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class BootstrapAdminRunnerTest {
    @Test
    void storesOnlyEncodedPasswordForFirstAccount() throws Exception {
        var jdbc = mock(JdbcTemplate.class);
        var encoder = mock(PasswordEncoder.class);
        String password = UUID.randomUUID().toString();
        when(jdbc.queryForObject(anyString(), eq(Integer.class))).thenReturn(0);
        when(encoder.encode(password)).thenReturn("encoded-hash");

        new BootstrapAdminRunner(jdbc, encoder, "admin", password).run(null);

        verify(encoder).encode(password);
        verify(jdbc).update(contains("INSERT INTO dbo.TAI_KHOAN"),
            eq("TK0001"), eq("NV0001"), eq("ADMIN"), eq("admin"), eq("encoded-hash"));
    }

    @Test
    void refusesToReplaceExistingAccounts() {
        var jdbc = mock(JdbcTemplate.class);
        var encoder = mock(PasswordEncoder.class);
        when(jdbc.queryForObject(anyString(), eq(Integer.class))).thenReturn(1);

        assertThrows(IllegalStateException.class, () ->
            new BootstrapAdminRunner(jdbc, encoder, "admin", UUID.randomUUID().toString()).run(null));

        verify(jdbc, never()).update(anyString(), eq("TK0001"), eq("NV0001"),
            eq("ADMIN"), eq("admin"), anyString());
    }
}
