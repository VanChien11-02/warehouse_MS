package vn.edu.dbms.bluestock.catalog.application;

public class CatalogReferenceException extends RuntimeException {
    public enum Kind { NOT_FOUND, CONFLICT, VALIDATION }

    private final Kind kind;
    private final String code;

    public CatalogReferenceException(Kind kind, String code, String message) {
        super(message);
        this.kind = kind;
        this.code = code;
    }

    public Kind kind() { return kind; }

    public String code() { return code; }
}
