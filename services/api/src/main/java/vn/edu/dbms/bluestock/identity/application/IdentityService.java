package vn.edu.dbms.bluestock.identity.application;

import java.util.List;
import java.util.Locale;
import java.util.function.Supplier;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.edu.dbms.bluestock.identity.application.IdentityException.Kind;
import vn.edu.dbms.bluestock.identity.application.IdentityModels.AccountPage;
import vn.edu.dbms.bluestock.identity.application.IdentityModels.AccountView;
import vn.edu.dbms.bluestock.identity.application.IdentityModels.EmployeeData;
import vn.edu.dbms.bluestock.identity.application.IdentityModels.EmployeePage;
import vn.edu.dbms.bluestock.identity.application.IdentityModels.EmployeeView;
import vn.edu.dbms.bluestock.identity.infrastructure.IdentityJdbcRepository;
import vn.edu.dbms.bluestock.platform.infrastructure.SqlErrorNumbers;
import vn.edu.dbms.bluestock.audit.application.AuditTrail;

@Service
public class IdentityService {
    private static final List<String> ROLES = List.of("ADMIN", "QLKHO", "NVKHO", "KETOAN");
    private final IdentityJdbcRepository repository;
    private final PasswordEncoder encoder;
    private final AuditTrail audit;

    public IdentityService(IdentityJdbcRepository repository, PasswordEncoder encoder,
        AuditTrail audit) {
        this.repository = repository;
        this.encoder = encoder;
        this.audit = audit;
    }

    @Transactional(readOnly = true)
    public EmployeePage listEmployees(int page, int size) {
        validatePagination(page, size);
        return repository.employeePage(page, size);
    }

    @Transactional(readOnly = true)
    public EmployeeView getEmployee(String code) {
        return repository.employee(normalizeCode(code)).orElseThrow(() ->
            new IdentityException(Kind.NOT_FOUND, "EMPLOYEE_NOT_FOUND", "Không tìm thấy nhân viên"));
    }

    @Transactional
    public EmployeeView createEmployee(String code, EmployeeData data, String actorAccount) {
        String normalizedCode = resolveCode(code, repository::nextEmployeeCode, "NV0001");
        EmployeeData normalized = normalizeEmployee(data);
        try {
            repository.insertEmployee(normalizedCode, normalized);
        } catch (DataIntegrityViolationException exception) {
            throw new IdentityException(Kind.CONFLICT, "EMPLOYEE_CONFLICT",
                "Mã nhân viên đã tồn tại hoặc dữ liệu không hợp lệ");
        }
        EmployeeView created = getEmployee(normalizedCode);
        audit.record(actorAccount, "CREATE", "NHAN_VIEN", normalizedCode, null, created);
        return created;
    }

    @Transactional
    public EmployeeView updateEmployee(String code, EmployeeData data,
        String actorEmployee, String actorAccount) {
        String normalizedCode = normalizeCode(code);
        repository.lockedEmployeeActive(normalizedCode).orElseThrow(() ->
            new IdentityException(Kind.NOT_FOUND, "EMPLOYEE_NOT_FOUND", "Không tìm thấy nhân viên"));
        EmployeeData normalized = normalizeEmployee(data);
        if (normalizedCode.equals(normalizeCode(actorEmployee)) && !normalized.dangLamViec()) {
            throw new IdentityException(Kind.CONFLICT, "SELF_DEACTIVATION_FORBIDDEN",
                "Không thể tự ngừng trạng thái làm việc");
        }
        EmployeeView before = getEmployee(normalizedCode);
        repository.updateEmployee(normalizedCode, normalized);
        EmployeeView after = getEmployee(normalizedCode);
        audit.record(actorAccount, "UPDATE", "NHAN_VIEN", normalizedCode, before, after);
        return after;
    }

    @Transactional(readOnly = true)
    public AccountPage listAccounts(int page, int size) {
        validatePagination(page, size);
        return repository.accountPage(page, size);
    }

    @Transactional(readOnly = true)
    public AccountView getAccount(String code) {
        return repository.account(normalizeCode(code)).orElseThrow(() ->
            new IdentityException(Kind.NOT_FOUND, "ACCOUNT_NOT_FOUND", "Không tìm thấy tài khoản"));
    }

    @Transactional
    public AccountView createAccount(String code, String employee, String username,
        String role, String password, String actorAccount) {
        String normalizedCode = resolveCode(code, repository::nextAccountCode, "TK0001");
        String normalizedEmployee = normalizeCode(employee);
        String normalizedRole = normalizeRole(role);
        String normalizedUsername = requireUsername(username);
        validatePassword(password);
        if (!repository.lockedEmployeeActive(normalizedEmployee).orElseThrow(() ->
            new IdentityException(Kind.NOT_FOUND, "EMPLOYEE_NOT_FOUND", "Không tìm thấy nhân viên"))) {
            throw new IdentityException(Kind.CONFLICT, "EMPLOYEE_INACTIVE",
                "Nhân viên đã ngừng làm việc");
        }
        try {
            repository.insertAccount(normalizedCode, normalizedEmployee,
                normalizedUsername, normalizedRole, encoder.encode(password));
        } catch (DataIntegrityViolationException exception) {
            int sqlNumber = SqlErrorNumbers.from(exception);
            if (sqlNumber == 2601 || sqlNumber == 2627) {
                throw new IdentityException(Kind.CONFLICT, "ACCOUNT_CONFLICT",
                    "Mã, tên tài khoản hoặc nhân viên đã được dùng");
            }
            throw new IdentityException(Kind.VALIDATION, "INVALID_REFERENCE",
                "Nhân viên hoặc role không hợp lệ");
        }
        AccountView created = getAccount(normalizedCode);
        audit.record(actorAccount, "CREATE", "TAI_KHOAN", normalizedCode, null, created);
        return created;
    }

    @Transactional
    public AccountView updateAccount(String code, String username, String role,
        boolean active, String actorAccount) {
        String normalizedCode = normalizeCode(code);
        String normalizedRole = normalizeRole(role);
        String normalizedUsername = requireUsername(username);
        AccountView before = repository.lockedAccount(normalizedCode).orElseThrow(() ->
            new IdentityException(Kind.NOT_FOUND, "ACCOUNT_NOT_FOUND", "Không tìm thấy tài khoản"));
        if (normalizedCode.equals(normalizeCode(actorAccount))
            && (!active || !"ADMIN".equals(normalizedRole))) {
            throw new IdentityException(Kind.CONFLICT, "SELF_ROLE_CHANGE_FORBIDDEN",
                "Không thể tự khóa hoặc bỏ quyền quản trị");
        }
        try {
            repository.updateAccount(normalizedCode, normalizedUsername, normalizedRole, active);
        } catch (DataIntegrityViolationException exception) {
            throw new IdentityException(Kind.CONFLICT, "ACCOUNT_CONFLICT",
                "Tên tài khoản đã được dùng");
        }
        AccountView after = getAccount(normalizedCode);
        audit.record(actorAccount, "UPDATE", "TAI_KHOAN", normalizedCode, before, after);
        return after;
    }

    @Transactional
    public void resetPassword(String code, String password, String actorAccount) {
        String normalizedCode = normalizeCode(code);
        validatePassword(password);
        repository.lockedAccount(normalizedCode).orElseThrow(() ->
            new IdentityException(Kind.NOT_FOUND, "ACCOUNT_NOT_FOUND", "Không tìm thấy tài khoản"));
        repository.resetPassword(normalizedCode, encoder.encode(password));
        audit.record(actorAccount, "PASSWORD_RESET", "TAI_KHOAN", normalizedCode, null, null);
    }

    private static EmployeeData normalizeEmployee(EmployeeData data) {
        if (data == null || data.tenNhanVien() == null || data.tenNhanVien().isBlank()
            || data.tenNhanVien().length() > 255 || data.ngayVaoLam() == null) {
            throw new IdentityException(Kind.VALIDATION, "INVALID_EMPLOYEE", "Thông tin nhân viên không hợp lệ");
        }
        String gender = optionalText(data.gioiTinh());
        if (gender != null && !List.of("Nam", "Nữ", "Khác").contains(gender)) {
            throw new IdentityException(Kind.VALIDATION, "INVALID_GENDER", "Giới tính không hợp lệ");
        }
        if (data.luong() != null && data.luong().signum() < 0) {
            throw new IdentityException(Kind.VALIDATION, "INVALID_SALARY", "Lương không được âm");
        }
        return new EmployeeData(data.tenNhanVien().trim(), optionalText(data.soDienThoai()),
            gender, data.ngaySinh(), optionalText(data.diaChi()), data.luong(),
            data.ngayVaoLam(), data.dangLamViec());
    }

    private static String normalizeRole(String role) {
        String normalized = role == null ? "" : role.trim().toUpperCase(Locale.ROOT);
        if (!ROLES.contains(normalized)) {
            throw new IdentityException(Kind.VALIDATION, "INVALID_ROLE", "Role không hợp lệ");
        }
        return normalized;
    }

    private static String requireUsername(String username) {
        String normalized = username == null ? "" : username.trim();
        if (normalized.isBlank() || normalized.length() > 100) {
            throw new IdentityException(Kind.VALIDATION, "INVALID_USERNAME", "Tên tài khoản không hợp lệ");
        }
        return normalized;
    }

    private static void validatePassword(String password) {
        if (password == null || password.length() < 12 || password.length() > 72) {
            throw new IdentityException(Kind.VALIDATION, "INVALID_PASSWORD",
                "Mật khẩu cần dài 12–72 ký tự");
        }
    }

    private static void validatePagination(int page, int size) {
        if (page < 0 || page > 1_000_000 || size < 1 || size > 100) {
            throw new IdentityException(Kind.VALIDATION, "INVALID_PAGINATION",
                "page hoặc size không hợp lệ");
        }
    }

    private static String resolveCode(String code, Supplier<String> generator, String fallback) {
        if (code == null || code.isBlank()) {
            String generated = generator.get();
            return generated == null || generated.isBlank() ? fallback : normalizeCode(generated);
        }
        return normalizeCode(code);
    }

    private static String normalizeCode(String code) {
        String normalized = code == null ? "" : code.trim().toUpperCase(Locale.ROOT);
        if (!normalized.matches("[A-Z0-9]{1,6}")) {
            throw new IdentityException(Kind.VALIDATION, "INVALID_CODE",
                "Mã phải gồm 1–6 ký tự chữ hoặc số");
        }
        return normalized;
    }

    private static String optionalText(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
