package vn.edu.dbms.bluestock.transfer.application;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.edu.dbms.bluestock.audit.application.AuditTrail;
import vn.edu.dbms.bluestock.platform.infrastructure.SqlErrorNumbers;
import vn.edu.dbms.bluestock.transfer.application.TransferException.Kind;
import vn.edu.dbms.bluestock.transfer.application.TransferModels.CompletionView;
import vn.edu.dbms.bluestock.transfer.application.TransferModels.LineData;
import vn.edu.dbms.bluestock.transfer.application.TransferModels.TransferView;
import vn.edu.dbms.bluestock.transfer.application.TransferModels.TransferPage;
import vn.edu.dbms.bluestock.transfer.infrastructure.TransferJdbcRepository;

@Service
public class TransferService {
    private final TransferJdbcRepository repository;
    private final AuditTrail audit;

    public TransferService(TransferJdbcRepository repository, AuditTrail audit) {
        this.repository = repository;
        this.audit = audit;
    }

    @Transactional(readOnly = true)
    public TransferView get(String code) {
        return repository.findByCode(normalizeCode(code)).orElseThrow(() ->
            new TransferException(Kind.NOT_FOUND, "TRANSFER_NOT_FOUND", "Không tìm thấy phiếu chuyển"));
    }

    @Transactional(readOnly = true)
    public TransferPage list(int page, int size, String status) {
        if (page < 0 || page > 1_000_000 || size < 1 || size > 100) {
            throw new TransferException(Kind.VALIDATION, "INVALID_PAGINATION",
                "page hoặc size không hợp lệ");
        }
        String normalizedStatus = status == null ? null : status.trim().toUpperCase(Locale.ROOT);
        if (normalizedStatus != null && !List.of("NHAP", "DA_HOAN_THANH", "DA_HUY").contains(normalizedStatus)) {
            throw new TransferException(Kind.VALIDATION, "INVALID_STATUS", "Trạng thái không hợp lệ");
        }
        return repository.findPage(page, size, normalizedStatus);
    }

    @Transactional
    public TransferView create(String employeeCode, String note, List<LineData> lines) {
        String normalizedEmployee = normalizeCode(employeeCode);
        List<LineData> normalizedLines = normalizeLines(lines);
        int number = repository.nextCodeNumber();
        if (number > 9999) {
            throw new TransferException(Kind.CONFLICT, "TRANSFER_CODE_EXHAUSTED",
                "Đã hết mã phiếu chuyển sáu ký tự");
        }
        String code = "PC%04d".formatted(number);
        try {
            repository.insertHeader(code, normalizedEmployee, optionalText(note));
            for (LineData line : normalizedLines) repository.insertLine(code, line);
        } catch (DataIntegrityViolationException exception) {
            throw new TransferException(Kind.VALIDATION, "INVALID_REFERENCE",
                "Nhân viên, lô hoặc vị trí không tồn tại");
        }
        return get(code);
    }

    @Transactional
    public TransferView update(String code, String note, List<LineData> lines) {
        String normalizedCode = normalizeCode(code);
        List<LineData> normalizedLines = normalizeLines(lines);
        requireDraft(normalizedCode);
        try {
            repository.updateNote(normalizedCode, optionalText(note));
            repository.replaceLines(normalizedCode, normalizedLines);
        } catch (DataIntegrityViolationException exception) {
            throw new TransferException(Kind.VALIDATION, "INVALID_REFERENCE",
                "Lô hoặc vị trí không tồn tại");
        }
        return get(normalizedCode);
    }

    @Transactional
    public TransferView cancel(String code, String actorAccount) {
        String normalizedCode = normalizeCode(code);
        requireDraft(normalizedCode);
        if (repository.cancel(normalizedCode) != 1) {
            throw new TransferException(Kind.CONFLICT, "TRANSFER_NOT_DRAFT",
                "Phiếu chuyển không còn ở trạng thái nháp");
        }
        audit.record(normalizeCode(actorAccount), "CANCEL", "PHIEU_CHUYEN_KHO", normalizedCode,
            Map.of("trangThai", "NHAP"), Map.of("trangThai", "DA_HUY"));
        return get(normalizedCode);
    }

    private void requireDraft(String code) {
        String status = repository.lockedStatus(code).orElseThrow(() ->
            new TransferException(Kind.NOT_FOUND, "TRANSFER_NOT_FOUND", "Không tìm thấy phiếu chuyển"));
        if (!"NHAP".equals(status)) {
            throw new TransferException(Kind.CONFLICT, "TRANSFER_NOT_DRAFT",
                "Phiếu chuyển không còn ở trạng thái nháp");
        }
    }

    public CompletionView complete(String code, String actorAccount) {
        try {
            return repository.complete(normalizeCode(code), normalizeCode(actorAccount));
        } catch (DataAccessException exception) {
            throw mapProcedureError(SqlErrorNumbers.from(exception));
        }
    }

    private static List<LineData> normalizeLines(List<LineData> lines) {
        if (lines == null || lines.isEmpty()) {
            throw new TransferException(Kind.VALIDATION, "LINES_REQUIRED",
                "Phiếu chuyển cần ít nhất một dòng");
        }
        var normalized = new ArrayList<LineData>();
        var keys = new HashSet<String>();
        for (LineData line : lines) {
            String lot = normalizeCode(line.maLo());
            String source = normalizeCode(line.maViTriNguon());
            String destination = normalizeCode(line.maViTriDich());
            if (source.equals(destination)) {
                throw new TransferException(Kind.VALIDATION, "SAME_POSITION",
                    "Vị trí nguồn và đích phải khác nhau");
            }
            if (line.soLuong() <= 0) {
                throw new TransferException(Kind.VALIDATION, "INVALID_QUANTITY",
                    "Số lượng chuyển phải lớn hơn 0");
            }
            if (!keys.add(lot + ":" + source + ":" + destination)) {
                throw new TransferException(Kind.VALIDATION, "DUPLICATE_TRANSFER_LINE",
                    "Một cặp lô/nguồn/đích chỉ có một dòng");
            }
            normalized.add(new LineData(lot, source, destination, line.soLuong()));
        }
        return normalized;
    }

    private static TransferException mapProcedureError(int number) {
        return switch (number) {
            case 51301 -> new TransferException(Kind.NOT_FOUND, "TRANSFER_NOT_FOUND",
                "Không tìm thấy phiếu chuyển");
            case 51302 -> new TransferException(Kind.CONFLICT, "TRANSFER_NOT_DRAFT",
                "Phiếu chuyển không còn ở trạng thái nháp");
            case 51303 -> new TransferException(Kind.VALIDATION, "LINES_REQUIRED",
                "Phiếu chuyển chưa có dòng");
            case 51304 -> new TransferException(Kind.VALIDATION, "INVALID_POSITION",
                "Vị trí chuyển không tồn tại");
            case 51305 -> new TransferException(Kind.VALIDATION, "INCOMPATIBLE_STORAGE",
                "Vị trí nguồn/đích không phù hợp để chuyển lô");
            case 51306 -> new TransferException(Kind.CONFLICT, "INSUFFICIENT_STOCK",
                "Tồn nguồn không đủ");
            case 51307 -> new TransferException(Kind.CONFLICT, "CAPACITY_EXCEEDED",
                "Sức chứa vị trí đích không đủ");
            case 51308 -> new TransferException(Kind.CONFLICT, "UNIT_MISMATCH",
                "Vị trí đích không được trộn đơn vị tính");
            default -> new TransferException(Kind.INTERNAL, "TRANSFER_POSTING_FAILED",
                "Không thể hoàn tất phiếu chuyển");
        };
    }

    private static String normalizeCode(String code) {
        String normalized = code == null ? "" : code.trim().toUpperCase(Locale.ROOT);
        if (!normalized.matches("[A-Z0-9]{1,6}")) {
            throw new TransferException(Kind.VALIDATION, "INVALID_CODE",
                "Mã phải gồm 1–6 ký tự chữ hoặc số");
        }
        return normalized;
    }

    private static String optionalText(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
