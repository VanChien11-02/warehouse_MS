package vn.edu.dbms.bluestock.outbound.application;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.HashSet;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.edu.dbms.bluestock.outbound.application.OutboundException.Kind;
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.CompletionView;
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.FefoAllocation;
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.FefoSuggestion;
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.LineData;
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.OutboundView;
import vn.edu.dbms.bluestock.outbound.application.OutboundModels.OutboundPage;
import vn.edu.dbms.bluestock.outbound.infrastructure.OutboundJdbcRepository;
import vn.edu.dbms.bluestock.inventory.application.AvailableStockQuery;
import vn.edu.dbms.bluestock.platform.infrastructure.SqlErrorNumbers;

@Service
public class OutboundService {
    private static final ZoneId BUSINESS_ZONE = ZoneId.of("Asia/Bangkok");
    private final OutboundJdbcRepository repository;
    private final AvailableStockQuery availableStock;

    public OutboundService(OutboundJdbcRepository repository, AvailableStockQuery availableStock) {
        this.repository = repository;
        this.availableStock = availableStock;
    }

    @Transactional(readOnly = true)
    public OutboundView get(String code) {
        return repository.findByCode(normalizeCode(code)).orElseThrow(() ->
            new OutboundException(Kind.NOT_FOUND, "OUTBOUND_NOT_FOUND", "Không tìm thấy phiếu xuất"));
    }

    @Transactional(readOnly = true)
    public OutboundPage list(int page, int size, String status, String recipientCode) {
        if (page < 0 || page > 1_000_000 || size < 1 || size > 100) {
            throw new OutboundException(Kind.VALIDATION, "INVALID_PAGINATION",
                "page hoặc size không hợp lệ");
        }
        String normalizedStatus = status == null ? null : status.trim().toUpperCase(Locale.ROOT);
        if (normalizedStatus != null && !List.of("NHAP", "DA_HOAN_THANH", "DA_HUY").contains(normalizedStatus)) {
            throw new OutboundException(Kind.VALIDATION, "INVALID_STATUS", "Trạng thái không hợp lệ");
        }
        return repository.findPage(page, size, normalizedStatus,
            recipientCode == null ? null : normalizeCode(recipientCode));
    }

    @Transactional
    public OutboundView create(String recipientCode, String employeeCode, String note, List<LineData> lines) {
        String normalizedRecipient = normalizeCode(recipientCode);
        String normalizedEmployee = normalizeCode(employeeCode);
        List<LineData> normalizedLines = normalizeLines(lines);
        int number = repository.nextCodeNumber();
        if (number > 9999) {
            throw new OutboundException(Kind.CONFLICT, "OUTBOUND_CODE_EXHAUSTED",
                "Đã hết mã phiếu xuất sáu ký tự");
        }
        String code = "PX%04d".formatted(number);
        try {
            repository.insertHeader(code, normalizedRecipient, normalizedEmployee, optionalText(note));
            for (LineData line : normalizedLines) repository.insertLine(code, line);
        } catch (DataIntegrityViolationException exception) {
            throw new OutboundException(Kind.VALIDATION, "INVALID_REFERENCE",
                "Đối tác, nhân viên, lô hoặc vị trí không tồn tại");
        }
        return get(code);
    }

    @Transactional
    public OutboundView update(String code, String recipientCode, String note, List<LineData> lines) {
        String normalizedCode = normalizeCode(code);
        String normalizedRecipient = normalizeCode(recipientCode);
        List<LineData> normalizedLines = normalizeLines(lines);
        requireDraft(normalizedCode);
        try {
            repository.updateHeader(normalizedCode, normalizedRecipient, optionalText(note));
            repository.replaceLines(normalizedCode, normalizedLines);
        } catch (DataIntegrityViolationException exception) {
            throw new OutboundException(Kind.VALIDATION, "INVALID_REFERENCE",
                "Đối tác, lô hoặc vị trí không tồn tại");
        }
        return get(normalizedCode);
    }

    @Transactional
    public OutboundView cancel(String code) {
        String normalizedCode = normalizeCode(code);
        requireDraft(normalizedCode);
        repository.cancel(normalizedCode);
        return get(normalizedCode);
    }

    private void requireDraft(String code) {
        String status = repository.lockedStatus(code).orElseThrow(() ->
            new OutboundException(Kind.NOT_FOUND, "OUTBOUND_NOT_FOUND", "Không tìm thấy phiếu xuất"));
        if (!"NHAP".equals(status)) {
            throw new OutboundException(Kind.CONFLICT, "OUTBOUND_NOT_DRAFT",
                "Phiếu xuất không còn ở trạng thái nháp");
        }
    }

    private static List<LineData> normalizeLines(List<LineData> lines) {
        if (lines == null || lines.isEmpty()) {
            throw new OutboundException(Kind.VALIDATION, "LINES_REQUIRED", "Phiếu xuất cần ít nhất một dòng");
        }
        var normalized = new ArrayList<LineData>();
        var sources = new HashSet<String>();
        for (LineData line : lines) {
            String lot = normalizeCode(line.maLo());
            String position = normalizeCode(line.maViTri());
            if (!sources.add(lot + ":" + position)) {
                throw new OutboundException(Kind.VALIDATION, "DUPLICATE_STOCK_SOURCE",
                    "Một cặp lô/vị trí chỉ có một dòng trên phiếu xuất");
            }
            normalized.add(new LineData(lot, position, line.soLuong(), line.donGiaXuat()));
        }
        return normalized;
    }

    public CompletionView complete(String code) {
        String normalizedCode = normalizeCode(code);
        LocalDate businessDate = LocalDate.now(BUSINESS_ZONE);
        try {
            return repository.complete(normalizedCode, businessDate);
        } catch (DataAccessException exception) {
            throw mapProcedureError(SqlErrorNumbers.from(exception));
        }
    }

    @Transactional(readOnly = true)
    public FefoSuggestion suggest(String code, String productCode, int quantity, String warehouseCode) {
        OutboundView document = get(code);
        if (!"NHAP".equals(document.trangThai())) {
            throw new OutboundException(Kind.CONFLICT, "OUTBOUND_NOT_DRAFT",
                "Phiếu xuất không còn ở trạng thái nháp");
        }
        if (quantity <= 0) {
            throw new OutboundException(Kind.VALIDATION, "INVALID_QUANTITY",
                "Số lượng gợi ý phải lớn hơn 0");
        }
        String normalizedProduct = normalizeCode(productCode);
        String normalizedWarehouse = warehouseCode == null ? null : normalizeCode(warehouseCode);
        int remaining = quantity;
        var allocations = new ArrayList<FefoAllocation>();
        for (var candidate : availableStock.findAvailable(normalizedProduct, normalizedWarehouse,
            LocalDate.now(BUSINESS_ZONE))) {
            if (remaining == 0) break;
            int taken = Math.min(remaining, candidate.soLuongTon());
            allocations.add(new FefoAllocation(candidate.maLo(), candidate.maViTri(),
                taken, candidate.hanSuDung()));
            remaining -= taken;
        }
        return new FefoSuggestion(document.maPhieuXuat(), normalizedProduct,
            quantity, remaining, allocations);
    }

    private static OutboundException mapProcedureError(int number) {
        return switch (number) {
            case 51201 -> new OutboundException(Kind.NOT_FOUND, "OUTBOUND_NOT_FOUND",
                "Không tìm thấy phiếu xuất");
            case 51202 -> new OutboundException(Kind.CONFLICT, "OUTBOUND_NOT_DRAFT",
                "Phiếu xuất không còn ở trạng thái nháp");
            case 51203 -> new OutboundException(Kind.VALIDATION, "BUSINESS_DATE_REQUIRED",
                "Thiếu ngày nghiệp vụ");
            case 51204 -> new OutboundException(Kind.VALIDATION, "LINES_REQUIRED",
                "Phiếu xuất chưa có dòng");
            case 51205 -> new OutboundException(Kind.VALIDATION, "INVALID_POSITION",
                "Vị trí xuất không tồn tại");
            case 51206 -> new OutboundException(Kind.VALIDATION, "STOCK_NOT_AVAILABLE",
                "Lô hết hạn hoặc ở vị trí không khả dụng");
            case 51207 -> new OutboundException(Kind.VALIDATION, "RECIPIENT_PRODUCT_NOT_LINKED",
                "Đối tác chưa liên kết với mọi sản phẩm");
            case 51208 -> new OutboundException(Kind.CONFLICT, "INSUFFICIENT_STOCK",
                "Tồn kho không đủ");
            case 51209 -> new OutboundException(Kind.CONFLICT, "FEFO_VIOLATION",
                "Cần dùng hết lô có hạn gần hơn trước");
            default -> new OutboundException(Kind.INTERNAL, "OUTBOUND_POSTING_FAILED",
                "Không thể hoàn tất phiếu xuất");
        };
    }

    private static String normalizeCode(String code) {
        String normalized = code == null ? "" : code.trim().toUpperCase(Locale.ROOT);
        if (!normalized.matches("[A-Z0-9]{1,6}")) {
            throw new OutboundException(Kind.VALIDATION, "INVALID_CODE",
                "Mã phải gồm 1–6 ký tự chữ hoặc số");
        }
        return normalized;
    }

    private static String optionalText(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
