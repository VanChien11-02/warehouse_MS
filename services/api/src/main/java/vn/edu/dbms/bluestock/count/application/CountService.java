package vn.edu.dbms.bluestock.count.application;

import java.util.List;
import java.util.Locale;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.edu.dbms.bluestock.count.application.CountException.Kind;
import vn.edu.dbms.bluestock.count.application.CountModels.CompletionView;
import vn.edu.dbms.bluestock.count.application.CountModels.CountPage;
import vn.edu.dbms.bluestock.count.application.CountModels.CountView;
import vn.edu.dbms.bluestock.count.infrastructure.CountJdbcRepository;
import vn.edu.dbms.bluestock.platform.infrastructure.SqlErrorNumbers;

@Service
public class CountService {
    private final CountJdbcRepository repository;

    public CountService(CountJdbcRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public CountView get(String code) {
        return repository.findByCode(normalizeCode(code)).orElseThrow(() ->
            new CountException(Kind.NOT_FOUND, "COUNT_NOT_FOUND", "Không tìm thấy phiếu kiểm kê"));
    }

    @Transactional(readOnly = true)
    public CountPage list(int page, int size, String status, String position) {
        if (page < 0 || page > 1_000_000 || size < 1 || size > 100) {
            throw new CountException(Kind.VALIDATION, "INVALID_PAGINATION",
                "page hoặc size không hợp lệ");
        }
        String normalizedStatus = status == null ? null : status.trim().toUpperCase(Locale.ROOT);
        if (normalizedStatus != null && !List.of("NHAP", "DA_HOAN_THANH", "DA_HUY").contains(normalizedStatus)) {
            throw new CountException(Kind.VALIDATION, "INVALID_STATUS", "Trạng thái không hợp lệ");
        }
        return repository.findPage(page, size, normalizedStatus,
            position == null ? null : normalizeCode(position));
    }

    @Transactional
    public CountView create(String employee, String position, String note) {
        String normalizedPosition = normalizeCode(position);
        if (!repository.lockPosition(normalizedPosition)) {
            throw new CountException(Kind.VALIDATION, "INVALID_POSITION", "Vị trí không tồn tại");
        }
        var snapshot = repository.lockPositiveStock(normalizedPosition);
        if (snapshot.isEmpty()) {
            throw new CountException(Kind.VALIDATION, "COUNT_LINES_REQUIRED",
                "Vị trí không có tồn dương để kiểm kê");
        }
        int number = repository.nextCodeNumber();
        if (number > 9999) {
            throw new CountException(Kind.CONFLICT, "COUNT_CODE_EXHAUSTED",
                "Đã hết mã phiếu kiểm kê sáu ký tự");
        }
        String code = "KK%04d".formatted(number);
        try {
            repository.insertHeader(code, normalizeCode(employee), normalizedPosition, optionalText(note));
            for (var stock : snapshot) repository.insertSnapshotLine(code, stock.maLo(), stock.soLuong());
        } catch (DataIntegrityViolationException exception) {
            throw new CountException(Kind.VALIDATION, "INVALID_REFERENCE",
                "Nhân viên hoặc vị trí không tồn tại");
        }
        return get(code);
    }

    @Transactional
    public CountView setActual(String code, String lot, Integer actual, String reason) {
        String normalizedCode = normalizeCode(code);
        String normalizedLot = normalizeCode(lot);
        requireDraft(normalizedCode);
        String position = repository.lockPositionForCount(normalizedCode);
        if (actual == null || actual < 0) {
            throw new CountException(Kind.VALIDATION, "INVALID_QUANTITY",
                "Số thực tế phải là số nguyên không âm");
        }
        String normalizedReason = optionalText(reason);
        if (normalizedReason != null && normalizedReason.length() > 500) {
            throw new CountException(Kind.VALIDATION, "INVALID_REASON", "Lý do quá dài");
        }
        if (repository.hasLine(normalizedCode, normalizedLot)) {
            repository.updateActual(normalizedCode, normalizedLot, actual, normalizedReason);
        } else {
            if (repository.lockStockQuantity(position, normalizedLot) > 0) {
                throw new CountException(Kind.CONFLICT, "COUNT_STALE_SNAPSHOT",
                    "Lô đã có tồn sau snapshot; cần lập phiếu mới");
            }
            try {
                repository.insertActualLine(normalizedCode, normalizedLot, actual, normalizedReason);
            } catch (DataIntegrityViolationException exception) {
                throw new CountException(Kind.VALIDATION, "INVALID_LOT", "Lô không tồn tại");
            }
        }
        return get(normalizedCode);
    }

    @Transactional
    public CountView cancel(String code) {
        String normalizedCode = normalizeCode(code);
        requireDraft(normalizedCode);
        repository.cancel(normalizedCode);
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
            new CountException(Kind.NOT_FOUND, "COUNT_NOT_FOUND", "Không tìm thấy phiếu kiểm kê"));
        if (!"NHAP".equals(status)) {
            throw new CountException(Kind.CONFLICT, "COUNT_NOT_DRAFT",
                "Phiếu kiểm kê không còn ở trạng thái nháp");
        }
    }

    private static CountException mapProcedureError(int number) {
        return switch (number) {
            case 51401 -> new CountException(Kind.NOT_FOUND, "COUNT_NOT_FOUND", "Không tìm thấy phiếu kiểm kê");
            case 51402 -> new CountException(Kind.CONFLICT, "COUNT_NOT_DRAFT", "Phiếu kiểm kê không còn là nháp");
            case 51403 -> new CountException(Kind.VALIDATION, "COUNT_LINES_REQUIRED", "Phiếu kiểm kê chưa có dòng");
            case 51404 -> new CountException(Kind.VALIDATION, "COUNT_ACTUAL_REQUIRED", "Thiếu số đếm thực tế");
            case 51405 -> new CountException(Kind.VALIDATION, "COUNT_REASON_REQUIRED", "Dòng chênh lệch cần lý do");
            case 51406 -> new CountException(Kind.CONFLICT, "COUNT_STALE_SNAPSHOT", "Tồn thay đổi sau snapshot");
            case 51407 -> new CountException(Kind.CONFLICT, "COUNT_CAPACITY_EXCEEDED", "Vượt sức chứa vị trí");
            case 51408 -> new CountException(Kind.VALIDATION, "COUNT_STORAGE_MISMATCH", "Loại bảo quản không phù hợp");
            case 51409 -> new CountException(Kind.VALIDATION, "COUNT_UNIT_MISMATCH", "Vị trí không được trộn đơn vị tính");
            default -> new CountException(Kind.INTERNAL, "COUNT_POSTING_FAILED", "Không thể hoàn tất kiểm kê");
        };
    }

    private static String normalizeCode(String code) {
        String normalized = code == null ? "" : code.trim().toUpperCase(Locale.ROOT);
        if (!normalized.matches("[A-Z0-9]{1,6}")) {
            throw new CountException(Kind.VALIDATION, "INVALID_CODE",
                "Mã phải gồm 1–6 ký tự chữ hoặc số");
        }
        return normalized;
    }

    private static String optionalText(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
