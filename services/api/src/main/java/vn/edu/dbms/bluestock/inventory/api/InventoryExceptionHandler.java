package vn.edu.dbms.bluestock.inventory.api;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import vn.edu.dbms.bluestock.inventory.application.InventoryException;
import vn.edu.dbms.bluestock.platform.api.ApiError;

@RestControllerAdvice
public class InventoryExceptionHandler {
    @ExceptionHandler(InventoryException.class)
    public ResponseEntity<ApiError> handle(InventoryException exception) {
        return ResponseEntity.unprocessableEntity()
            .body(ApiError.of(exception.code(), exception.getMessage()));
    }
}
