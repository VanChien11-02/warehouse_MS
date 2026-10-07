package vn.edu.dbms.bluestock.audit.api;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import vn.edu.dbms.bluestock.audit.application.AuditException;
import vn.edu.dbms.bluestock.platform.api.ApiError;

@RestControllerAdvice
public class AuditExceptionHandler {
    @ExceptionHandler(AuditException.class)
    public ResponseEntity<ApiError> handle(AuditException exception) {
        return ResponseEntity.unprocessableEntity()
            .body(ApiError.of(exception.code(), exception.getMessage()));
    }
}
