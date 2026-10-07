package vn.edu.dbms.bluestock.auth.api;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import vn.edu.dbms.bluestock.auth.application.PasswordChangeException;
import vn.edu.dbms.bluestock.platform.api.ApiError;

@RestControllerAdvice
public class PasswordChangeExceptionHandler {
    @ExceptionHandler(PasswordChangeException.class)
    public ResponseEntity<ApiError> handle(PasswordChangeException exception) {
        return ResponseEntity.unprocessableEntity()
            .body(ApiError.of("PASSWORD_REUSED", exception.getMessage()));
    }
}
