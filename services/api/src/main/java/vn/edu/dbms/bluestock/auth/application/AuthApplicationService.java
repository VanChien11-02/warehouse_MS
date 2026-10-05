package vn.edu.dbms.bluestock.auth.application;

import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;

@Service
public class AuthApplicationService {
    private final AuthenticationManager authenticationManager;

    public AuthApplicationService(AuthenticationManager authenticationManager) {
        this.authenticationManager = authenticationManager;
    }

    public Authentication authenticate(String username, String password) {
        return authenticationManager.authenticate(
            UsernamePasswordAuthenticationToken.unauthenticated(username, password));
    }
}
