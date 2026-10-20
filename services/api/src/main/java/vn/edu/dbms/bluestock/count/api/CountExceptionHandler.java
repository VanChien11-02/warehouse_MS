package vn.edu.dbms.bluestock.count.api;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import vn.edu.dbms.bluestock.count.application.CountException;
import vn.edu.dbms.bluestock.platform.api.ApiError;

@RestControllerAdvice
public class CountExceptionHandler {
    @ExceptionHandler(CountException.class)
    public ResponseEntity<ApiError> handle(CountException exception) {
        HttpStatus status = switch (exception.kind()) {
            case NOT_FOUND -> HttpStatus.NOT_FOUND;
            case CONFLICT -> HttpStatus.CONFLICT;
            case VALIDATION -> HttpStatus.UNPROCESSABLE_ENTITY;
            case INTERNAL -> HttpStatus.INTERNAL_SERVER_ERROR;
        };
        return ResponseEntity.status(status)
            .body(ApiError.of(exception.code(), exception.getMessage()));
    }
}
