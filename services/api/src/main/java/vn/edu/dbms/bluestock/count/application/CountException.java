package vn.edu.dbms.bluestock.count.application;

public class CountException extends RuntimeException {
    public enum Kind { NOT_FOUND, CONFLICT, VALIDATION, INTERNAL }

    private final Kind kind;
    private final String code;

    public CountException(Kind kind, String code, String message) {
        super(message);
        this.kind = kind;
        this.code = code;
    }

    public Kind kind() { return kind; }

    public String code() { return code; }
}
