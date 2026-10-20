package vn.edu.dbms.bluestock.inventory.application;

public class InventoryException extends RuntimeException {
    private final String code;

    public InventoryException(String code, String message) {
        super(message);
        this.code = code;
    }

    public String code() { return code; }
}
