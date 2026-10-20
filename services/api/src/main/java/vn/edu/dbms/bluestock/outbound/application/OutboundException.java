package vn.edu.dbms.bluestock.outbound.application;

public class OutboundException extends RuntimeException {
    public enum Kind { NOT_FOUND, CONFLICT, VALIDATION, INTERNAL }

    private final Kind kind;
    private final String code;

    public OutboundException(Kind kind, String code, String message) {
        super(message);
        this.kind = kind;
        this.code = code;
    }

    public Kind kind() { return kind; }

    public String code() { return code; }
}
