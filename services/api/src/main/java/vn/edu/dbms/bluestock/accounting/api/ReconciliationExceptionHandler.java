package vn.edu.dbms.bluestock.accounting.api;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import vn.edu.dbms.bluestock.accounting.application.ReconciliationException;
import vn.edu.dbms.bluestock.platform.api.ApiError;

@RestControllerAdvice
public class ReconciliationExceptionHandler {
    @ExceptionHandler(ReconciliationException.class)
    public ResponseEntity<ApiError> handle(ReconciliationException exception) {
        HttpStatus status = switch (exception.kind()) {
            case NOT_FOUND -> HttpStatus.NOT_FOUND;
            case CONFLICT -> HttpStatus.CONFLICT;
            case VALIDATION -> HttpStatus.UNPROCESSABLE_ENTITY;
        };
        return ResponseEntity.status(status).body(ApiError.of(exception.code(), exception.getMessage()));
    }
}
