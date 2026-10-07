package vn.edu.dbms.bluestock.auth.application;

public class PasswordChangeException extends RuntimeException {
    public PasswordChangeException() {
        super("Mật khẩu mới phải khác mật khẩu hiện tại");
    }
}
