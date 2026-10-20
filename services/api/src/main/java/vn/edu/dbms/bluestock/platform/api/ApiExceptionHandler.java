package vn.edu.dbms.bluestock.platform.api;

import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

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
                error.getField(), fieldCode(error.getCode()), "Giá trị không hợp lệ"))
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

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ApiError> invalidParameter() {
        return ResponseEntity.badRequest()
            .body(ApiError.of("INVALID_PARAMETER", "Tham số URL không hợp lệ"));
    }

    private static String fieldCode(String validationCode) {
        if (validationCode == null) return "INVALID_VALUE";
        return switch (validationCode) {
            case "NotBlank", "NotNull" -> "REQUIRED";
            case "DecimalMin" -> "NON_NEGATIVE_REQUIRED";
            case "Min" -> "NON_NEGATIVE_REQUIRED";
            case "Digits" -> "INVALID_PRECISION";
            case "Size" -> "INVALID_LENGTH";
            default -> "INVALID_VALUE";
        };
    }
}
