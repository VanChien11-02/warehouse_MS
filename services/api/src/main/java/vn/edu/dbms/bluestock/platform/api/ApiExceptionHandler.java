package vn.edu.dbms.bluestock.platform.api;

import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class ApiExceptionHandler {
    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ApiError> badCredentials() {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
            .body(ApiError.of("INVALID_CREDENTIALS", "Tên tài khoản hoặc mật khẩu không đúng"));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> validation(MethodArgumentNotValidException exception) {
        var fieldErrors = exception.getBindingResult().getFieldErrors().stream()
            .map(error -> new ApiError.FieldError(
                error.getField(), "REQUIRED", "Trường bắt buộc"))
            .toList();
        return ResponseEntity.unprocessableEntity()
            .body(new ApiError("VALIDATION_FAILED", "Dữ liệu không hợp lệ", fieldErrors,
                UUID.randomUUID().toString()));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiError> malformedJson() {
        return ResponseEntity.badRequest()
            .body(ApiError.of("MALFORMED_JSON", "JSON không hợp lệ"));
    }
}
