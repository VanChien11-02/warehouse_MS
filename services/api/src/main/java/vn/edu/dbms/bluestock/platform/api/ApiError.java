package vn.edu.dbms.bluestock.platform.api;

import java.util.List;
import java.util.UUID;

public record ApiError(String code, String message, List<FieldError> fieldErrors, String traceId) {
    public static ApiError of(String code, String message) {
        return new ApiError(code, message, List.of(), UUID.randomUUID().toString());
    }

    public record FieldError(String field, String code, String message) {}
}
