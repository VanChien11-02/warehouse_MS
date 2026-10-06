package vn.edu.dbms.bluestock.reporting.application;

public class ReportingException extends RuntimeException {
    private final String code;

    public ReportingException(String code, String message) {
        super(message);
        this.code = code;
    }

    public String code() { return code; }
}
