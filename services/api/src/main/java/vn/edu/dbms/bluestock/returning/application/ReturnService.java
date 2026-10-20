package vn.edu.dbms.bluestock.returning.application;

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
import vn.edu.dbms.bluestock.returning.application.ReturnException.Kind;
import vn.edu.dbms.bluestock.returning.application.ReturnModels.CompletionView;
import vn.edu.dbms.bluestock.returning.application.ReturnModels.LineData;
import vn.edu.dbms.bluestock.returning.application.ReturnModels.ReturnPage;
import vn.edu.dbms.bluestock.returning.application.ReturnModels.ReturnView;
import vn.edu.dbms.bluestock.returning.infrastructure.ReturnJdbcRepository;

@Service
public class ReturnService {
    private final ReturnJdbcRepository repository;
    private final AuditTrail audit;

    public ReturnService(ReturnJdbcRepository repository, AuditTrail audit) {
        this.repository = repository;
        this.audit = audit;
    }

    @Transactional(readOnly = true)
    public ReturnView get(String code) {
        return repository.findByCode(normalizeCode(code)).orElseThrow(() ->
            new ReturnException(Kind.NOT_FOUND, "RETURN_NOT_FOUND", "Không tìm thấy phiếu trả"));
    }

    @Transactional(readOnly = true)
    public ReturnPage list(int page, int size, String status, String outboundCode) {
        if (page < 0 || page > 1_000_000 || size < 1 || size > 100) {
            throw new ReturnException(Kind.VALIDATION, "INVALID_PAGINATION", "page hoặc size không hợp lệ");
        }
        String normalizedStatus = status == null ? null : status.trim().toUpperCase(Locale.ROOT);
        if (normalizedStatus != null && !List.of("NHAP", "DA_HOAN_THANH", "DA_HUY").contains(normalizedStatus)) {
            throw new ReturnException(Kind.VALIDATION, "INVALID_STATUS", "Trạng thái không hợp lệ");
        }
        return repository.findPage(page, size, normalizedStatus,
            outboundCode == null ? null : normalizeCode(outboundCode));
    }

    @Transactional
    public ReturnView create(String employee, String outboundCode, String note, List<LineData> lines) {
        String normalizedOutbound = normalizeCode(outboundCode);
        String outboundStatus = repository.outboundStatus(normalizedOutbound).orElseThrow(() ->
            new ReturnException(Kind.NOT_FOUND, "OUTBOUND_NOT_FOUND", "Không tìm thấy phiếu xuất gốc"));
        if (!"DA_HOAN_THANH".equals(outboundStatus)) {
            throw new ReturnException(Kind.CONFLICT, "OUTBOUND_NOT_COMPLETED",
                "Phiếu xuất gốc chưa hoàn tất");
        }
        List<LineData> normalizedLines = normalizeLines(lines);
        int number = repository.nextCodeNumber();
        if (number > 9999) {
            throw new ReturnException(Kind.CONFLICT, "RETURN_CODE_EXHAUSTED",
                "Đã hết mã phiếu trả sáu ký tự");
        }
        String code = "TH%04d".formatted(number);
        try {
            repository.insertHeader(code, normalizedOutbound, normalizeCode(employee), optionalText(note));
            for (LineData line : normalizedLines) repository.insertLine(code, line);
        } catch (DataIntegrityViolationException exception) {
            throw new ReturnException(Kind.VALIDATION, "INVALID_REFERENCE",
                "Nhân viên, lô hoặc vị trí không tồn tại");
        }
        return get(code);
    }

    @Transactional
    public ReturnView update(String code, String note, List<LineData> lines) {
        String normalizedCode = normalizeCode(code);
        List<LineData> normalizedLines = normalizeLines(lines);
        requireDraft(normalizedCode);
        try {
            repository.updateNote(normalizedCode, optionalText(note));
            repository.replaceLines(normalizedCode, normalizedLines);
        } catch (DataIntegrityViolationException exception) {
            throw new ReturnException(Kind.VALIDATION, "INVALID_REFERENCE",
                "Lô hoặc vị trí không tồn tại");
        }
        return get(normalizedCode);
    }

    @Transactional
    public ReturnView cancel(String code, String actorAccount) {
        String normalizedCode = normalizeCode(code);
        requireDraft(normalizedCode);
        if (repository.cancel(normalizedCode) != 1) {
            throw new ReturnException(Kind.CONFLICT, "RETURN_NOT_DRAFT",
                "Phiếu trả không còn ở trạng thái nháp");
        }
        audit.record(normalizeCode(actorAccount), "CANCEL", "PHIEU_TRA_HANG", normalizedCode,
            Map.of("trangThai", "NHAP"), Map.of("trangThai", "DA_HUY"));
        return get(normalizedCode);
    }

    public CompletionView complete(String code, String actorAccount) {
        try {
            return repository.complete(normalizeCode(code), normalizeCode(actorAccount));
        } catch (DataAccessException exception) {
            throw mapProcedureError(SqlErrorNumbers.from(exception));
        }
    }

    private void requireDraft(String code) {
        String status = repository.lockedStatus(code).orElseThrow(() ->
            new ReturnException(Kind.NOT_FOUND, "RETURN_NOT_FOUND", "Không tìm thấy phiếu trả"));
        if (!"NHAP".equals(status)) {
            throw new ReturnException(Kind.CONFLICT, "RETURN_NOT_DRAFT", "Phiếu trả không còn là nháp");
        }
    }

    private static List<LineData> normalizeLines(List<LineData> lines) {
        if (lines == null || lines.isEmpty()) {
            throw new ReturnException(Kind.VALIDATION, "LINES_REQUIRED", "Phiếu trả cần ít nhất một dòng");
        }
        var normalized = new ArrayList<LineData>();
        var lots = new HashSet<String>();
        for (LineData line : lines) {
            String lot = normalizeCode(line.maLo());
            String position = normalizeCode(line.maViTri());
            if (line.soLuong() <= 0) {
                throw new ReturnException(Kind.VALIDATION, "INVALID_QUANTITY",
                    "Số lượng trả phải lớn hơn 0");
            }
            if (!List.of("Tốt", "Hư hỏng").contains(line.tinhTrang())) {
                throw new ReturnException(Kind.VALIDATION, "INVALID_CONDITION",
                    "Tình trạng phải là Tốt hoặc Hư hỏng");
            }
            if (!lots.add(lot)) {
                throw new ReturnException(Kind.VALIDATION, "DUPLICATE_RETURN_LINE",
                    "Một lô chỉ có một dòng trên phiếu trả");
            }
            normalized.add(new LineData(lot, position, line.soLuong(), line.tinhTrang()));
        }
        return normalized;
    }

    private static ReturnException mapProcedureError(int number) {
        return switch (number) {
            case 51501 -> new ReturnException(Kind.NOT_FOUND, "RETURN_NOT_FOUND", "Không tìm thấy phiếu trả");
            case 51502 -> new ReturnException(Kind.CONFLICT, "RETURN_NOT_DRAFT", "Phiếu trả không còn là nháp");
            case 51503 -> new ReturnException(Kind.VALIDATION, "LINES_REQUIRED", "Phiếu trả chưa có dòng");
            case 51504 -> new ReturnException(Kind.CONFLICT, "OUTBOUND_NOT_COMPLETED", "Phiếu xuất gốc chưa hoàn tất");
            case 51505 -> new ReturnException(Kind.CONFLICT, "RETURN_LIMIT_EXCEEDED", "Lô chưa xuất hoặc số trả vượt lượng xuất");
            case 51506 -> new ReturnException(Kind.VALIDATION, "INCOMPATIBLE_STORAGE", "Vị trí không phù hợp tình trạng/bảo quản");
            case 51507 -> new ReturnException(Kind.CONFLICT, "CAPACITY_EXCEEDED", "Sức chứa vị trí trả không đủ");
            case 51508 -> new ReturnException(Kind.CONFLICT, "UNIT_MISMATCH", "Vị trí trả không được trộn đơn vị tính");
            default -> new ReturnException(Kind.INTERNAL, "RETURN_POSTING_FAILED", "Không thể hoàn tất phiếu trả");
        };
    }

    private static String normalizeCode(String code) {
        String normalized = code == null ? "" : code.trim().toUpperCase(Locale.ROOT);
        if (!normalized.matches("[A-Z0-9]{1,6}")) {
            throw new ReturnException(Kind.VALIDATION, "INVALID_CODE", "Mã phải gồm 1–6 ký tự chữ hoặc số");
        }
        return normalized;
    }

    private static String optionalText(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
