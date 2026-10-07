package vn.edu.dbms.bluestock.inbound.application;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.edu.dbms.bluestock.audit.application.AuditTrail;
import vn.edu.dbms.bluestock.inbound.application.InboundException.Kind;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.AllocationData;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.CompletionView;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.InboundView;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.InboundPage;
import vn.edu.dbms.bluestock.inbound.application.InboundModels.LineData;
import vn.edu.dbms.bluestock.inbound.infrastructure.InboundJdbcRepository;
import vn.edu.dbms.bluestock.platform.infrastructure.SqlErrorNumbers;

@Service
public class InboundService {
    private final InboundJdbcRepository repository;
    private final ObjectMapper objectMapper;
    private final AuditTrail audit;

    public InboundService(InboundJdbcRepository repository, ObjectMapper objectMapper,
        AuditTrail audit) {
        this.repository = repository;
        this.objectMapper = objectMapper;
        this.audit = audit;
    }

    @Transactional(readOnly = true)
    public InboundView get(String code) {
        return repository.findByCode(normalizeCode(code)).orElseThrow(() ->
            new InboundException(Kind.NOT_FOUND, "INBOUND_NOT_FOUND", "Không tìm thấy phiếu nhập"));
    }

    @Transactional(readOnly = true)
    public InboundPage list(int page, int size, String status, String supplierCode) {
        if (page < 0 || page > 1_000_000 || size < 1 || size > 100) {
            throw new InboundException(Kind.VALIDATION, "INVALID_PAGINATION",
                "page hoặc size không hợp lệ");
        }
        String normalizedStatus = status == null ? null : status.trim().toUpperCase(Locale.ROOT);
        if (normalizedStatus != null && !List.of("NHAP", "DA_HOAN_THANH", "DA_HUY").contains(normalizedStatus)) {
            throw new InboundException(Kind.VALIDATION, "INVALID_STATUS", "Trạng thái không hợp lệ");
        }
        return repository.findPage(page, size, normalizedStatus,
            supplierCode == null ? null : normalizeCode(supplierCode));
    }

    @Transactional
    public InboundView create(String supplierCode, String employeeCode, String note, List<LineData> lines) {
        String normalizedSupplier = normalizeCode(supplierCode);
        String normalizedEmployee = normalizeCode(employeeCode);
        List<LineData> normalizedLines = normalizeLines(lines);
        int number = repository.nextCodeNumber();
        if (number > 9999) {
            throw new InboundException(Kind.CONFLICT, "INBOUND_CODE_EXHAUSTED",
                "Đã hết mã phiếu nhập sáu ký tự");
        }
        String code = "PN%04d".formatted(number);
        try {
            repository.insertHeader(code, normalizedSupplier, normalizedEmployee, optionalText(note));
            for (LineData line : normalizedLines) repository.insertLine(code, line);
        } catch (DataIntegrityViolationException exception) {
            throw new InboundException(Kind.VALIDATION, "INVALID_REFERENCE",
                "Nhà cung cấp, nhân viên hoặc sản phẩm không tồn tại");
        }
        return get(code);
    }

    @Transactional
    public InboundView update(String code, String supplierCode, String note, List<LineData> lines) {
        String normalizedCode = normalizeCode(code);
        String normalizedSupplier = normalizeCode(supplierCode);
        List<LineData> normalizedLines = normalizeLines(lines);
        requireDraft(normalizedCode);
        try {
            repository.updateHeader(normalizedCode, normalizedSupplier, optionalText(note));
            repository.replaceLines(normalizedCode, normalizedLines);
        } catch (DataIntegrityViolationException exception) {
            throw new InboundException(Kind.VALIDATION, "INVALID_REFERENCE",
                "Nhà cung cấp hoặc sản phẩm không tồn tại");
        }
        return get(normalizedCode);
    }

    @Transactional
    public InboundView cancel(String code, String actorAccount) {
        String normalizedCode = normalizeCode(code);
        requireDraft(normalizedCode);
        if (repository.cancel(normalizedCode) != 1) {
            throw new InboundException(Kind.CONFLICT, "INBOUND_NOT_DRAFT",
                "Phiếu nhập không còn ở trạng thái nháp");
        }
        audit.record(normalizeCode(actorAccount), "CANCEL", "PHIEU_NHAP", normalizedCode,
            Map.of("trangThai", "NHAP"), Map.of("trangThai", "DA_HUY"));
        return get(normalizedCode);
    }

    private void requireDraft(String code) {
        String status = repository.lockedStatus(code).orElseThrow(() ->
            new InboundException(Kind.NOT_FOUND, "INBOUND_NOT_FOUND", "Không tìm thấy phiếu nhập"));
        if (!"NHAP".equals(status)) {
            throw new InboundException(Kind.CONFLICT, "INBOUND_NOT_DRAFT",
                "Phiếu nhập không còn ở trạng thái nháp");
        }
    }

    private static List<LineData> normalizeLines(List<LineData> lines) {
        if (lines == null || lines.isEmpty()) {
            throw new InboundException(Kind.VALIDATION, "LINES_REQUIRED", "Phiếu nhập cần ít nhất một dòng");
        }
        var normalized = new java.util.ArrayList<LineData>();
        var products = new HashSet<String>();
        for (LineData line : lines) {
            String productCode = normalizeCode(line.maSanPham());
            if (!products.add(productCode)) {
                throw new InboundException(Kind.VALIDATION, "DUPLICATE_PRODUCT",
                    "Một sản phẩm chỉ có một dòng trên phiếu nhập");
            }
            normalized.add(new LineData(productCode, line.soLuong(), line.donGiaNhap()));
        }
        return normalized;
    }

    public CompletionView complete(String code, List<AllocationData> allocations,
        String actorAccount) {
        String normalizedCode = normalizeCode(code);
        if (allocations == null || allocations.isEmpty()) {
            throw new InboundException(Kind.VALIDATION, "ALLOCATIONS_REQUIRED",
                "Cần phân bổ lô vào vị trí");
        }
        var normalized = allocations.stream()
            .map(item -> new AllocationWire(normalizeCode(item.maSanPham()),
                normalizeCode(item.maViTri()), item.soLuong(), dateText(item.ngaySanXuat()),
                dateText(item.hanSuDung())))
            .toList();
        String json;
        try {
            json = objectMapper.writeValueAsString(normalized);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Không tạo được dữ liệu phân bổ", exception);
        }
        try {
            return repository.complete(normalizedCode, json, normalizeCode(actorAccount));
        } catch (DataAccessException exception) {
            throw mapProcedureError(SqlErrorNumbers.from(exception));
        }
    }

    private static InboundException mapProcedureError(int number) {
        return switch (number) {
            case 51101 -> new InboundException(Kind.NOT_FOUND, "INBOUND_NOT_FOUND",
                "Không tìm thấy phiếu nhập");
            case 51102 -> new InboundException(Kind.CONFLICT, "INBOUND_NOT_DRAFT",
                "Phiếu nhập không còn ở trạng thái nháp");
            case 51103, 51104, 51107, 51108 -> new InboundException(Kind.VALIDATION,
                "INVALID_ALLOCATION", "Phân bổ lô không hợp lệ");
            case 51105 -> new InboundException(Kind.VALIDATION, "LINES_REQUIRED",
                "Phiếu nhập chưa có dòng sản phẩm");
            case 51106 -> new InboundException(Kind.VALIDATION, "SUPPLIER_PRODUCT_NOT_LINKED",
                "Nhà cung cấp chưa liên kết với mọi sản phẩm");
            case 51109 -> new InboundException(Kind.VALIDATION, "INVALID_POSITION",
                "Vị trí nhận hàng không tồn tại");
            case 51110 -> new InboundException(Kind.VALIDATION, "INCOMPATIBLE_STORAGE",
                "Vị trí không phù hợp loại bảo quản hoặc hàng nhập");
            case 51111 -> new InboundException(Kind.CONFLICT, "UNIT_MISMATCH",
                "Vị trí đang chứa đơn vị tính khác");
            case 51112 -> new InboundException(Kind.CONFLICT, "CAPACITY_EXCEEDED",
                "Sức chứa vị trí không đủ");
            case 51113 -> new InboundException(Kind.CONFLICT, "LOT_CODE_EXHAUSTED",
                "Đã hết mã lô sáu ký tự");
            default -> new InboundException(Kind.INTERNAL, "INBOUND_POSTING_FAILED",
                "Không thể hoàn tất phiếu nhập");
        };
    }

    private static String normalizeCode(String code) {
        String normalized = code == null ? "" : code.trim().toUpperCase(Locale.ROOT);
        if (!normalized.matches("[A-Z0-9]{1,6}")) {
            throw new InboundException(Kind.VALIDATION, "INVALID_CODE",
                "Mã phải gồm 1–6 ký tự chữ hoặc số");
        }
        return normalized;
    }

    private static String optionalText(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private static String dateText(LocalDate value) {
        return value == null ? null : value.toString();
    }

    private record AllocationWire(String maSanPham, String maViTri, int soLuong,
        String ngaySanXuat, String hanSuDung) {}
}
