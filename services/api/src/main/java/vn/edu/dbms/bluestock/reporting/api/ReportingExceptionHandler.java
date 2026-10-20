package vn.edu.dbms.bluestock.reporting.api;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import vn.edu.dbms.bluestock.platform.api.ApiError;
import vn.edu.dbms.bluestock.reporting.application.ReportingException;

@RestControllerAdvice
public class ReportingExceptionHandler {
    @ExceptionHandler(ReportingException.class)
    public ResponseEntity<ApiError> handle(ReportingException exception) {
        return ResponseEntity.unprocessableEntity()
            .body(ApiError.of(exception.code(), exception.getMessage()));
    }
}
