package vn.edu.dbms.bluestock.auth.infrastructure;

import java.util.Collection;
import java.util.List;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

public record AccountPrincipal(
    String maTaiKhoan,
    String maNhanVien,
    String tenNhanVien,
    String username,
    String password,
    String roleCode,
    boolean enabled
) implements UserDetails {
    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + roleCode));
    }

    @Override
    public String getPassword() {
        return password;
    }

    @Override
    public String getUsername() {
        return username;
    }

    @Override
    public boolean isEnabled() {
        return enabled;
    }

    @Override
    public String toString() {
        return "AccountPrincipal[maTaiKhoan=" + maTaiKhoan + ", username=" + username
            + ", roleCode=" + roleCode + "]";
    }
}
