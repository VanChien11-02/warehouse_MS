package vn.edu.dbms.bluestock.platform.infrastructure;

import java.sql.SQLException;
import org.springframework.dao.DataAccessException;

public final class SqlErrorNumbers {
    private SqlErrorNumbers() {}

    public static int from(DataAccessException exception) {
        Throwable cause = exception;
        while (cause != null) {
            if (cause instanceof SQLException sqlException && sqlException.getErrorCode() != 0) {
                return sqlException.getErrorCode();
            }
            cause = cause.getCause();
        }
        return 0;
    }
}
