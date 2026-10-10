package vn.edu.dbms.bluestock.warehouse.api;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import vn.edu.dbms.bluestock.platform.api.ApiError;
import vn.edu.dbms.bluestock.warehouse.application.WarehouseException;

@RestControllerAdvice
public class WarehouseExceptionHandler {
    @ExceptionHandler(WarehouseException.class)
    public ResponseEntity<ApiError> handle(WarehouseException exception) {
        HttpStatus status = switch (exception.kind()) {
            case NOT_FOUND -> HttpStatus.NOT_FOUND;
            case CONFLICT -> HttpStatus.CONFLICT;
            case VALIDATION -> HttpStatus.UNPROCESSABLE_ENTITY;
        };
        return ResponseEntity.status(status)
            .body(ApiError.of(exception.code(), exception.getMessage()));
    }
}
