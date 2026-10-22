package vn.edu.dbms.bluestock.accounting.application;

import java.math.BigDecimal;
import java.util.Locale;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.edu.dbms.bluestock.accounting.application.ReconciliationException.Kind;
import vn.edu.dbms.bluestock.accounting.application.ReconciliationModels.ReconciliationView;
import vn.edu.dbms.bluestock.accounting.infrastructure.ReconciliationJdbcRepository;
import vn.edu.dbms.bluestock.audit.application.AuditTrail;

@Service
public class ReconciliationService {
    private final ReconciliationJdbcRepository repository;
    private final AuditTrail audit;

    public ReconciliationService(ReconciliationJdbcRepository repository, AuditTrail audit) {
        this.repository = repository;
        this.audit = audit;
    }

    @Transactional(readOnly = true)
    public ReconciliationView get(String type, String code) {
        String normalizedType = type(type);
        String normalizedCode = code(code);
        return repository.find(normalizedType, normalizedCode).orElseThrow(() ->
            new ReconciliationException(Kind.NOT_FOUND, "RECONCILIATION_NOT_FOUND",
                "Chứng từ chưa được đối soát"));
    }

    @Transactional
    public ReconciliationView reconcile(String type, String code, BigDecimal checkedValue,
        String note, String actor) {
        String normalizedType = type(type);
        String normalizedCode = code(code);
        if (checkedValue == null || checkedValue.signum() < 0 || checkedValue.scale() > 4
            || checkedValue.precision() - checkedValue.scale() > 15)
            throw new ReconciliationException(Kind.VALIDATION, "INVALID_RECONCILED_VALUE",
                "Giá trị đối soát phải không âm và có tối đa bốn chữ số thập phân");
        String status = repository.lockedDocumentStatus(normalizedType, normalizedCode)
            .orElseThrow(() -> new ReconciliationException(Kind.NOT_FOUND, "DOCUMENT_NOT_FOUND",
                "Không tìm thấy chứng từ"));
        if (!status.equals("DA_HOAN_THANH"))
            throw new ReconciliationException(Kind.CONFLICT, "DOCUMENT_NOT_COMPLETED",
                "Chỉ đối soát chứng từ đã hoàn tất");
        if (repository.find(normalizedType, normalizedCode).isPresent())
            throw new ReconciliationException(Kind.CONFLICT, "ALREADY_RECONCILED",
                "Chứng từ đã được đối soát");
        BigDecimal documentValue = repository.documentValue(normalizedType, normalizedCode);
        String cleanedNote = note == null || note.isBlank() ? null : note.trim();
        boolean matched = checkedValue.compareTo(documentValue) == 0;
        if (!matched && cleanedNote == null)
            throw new ReconciliationException(Kind.VALIDATION, "DISCREPANCY_NOTE_REQUIRED",
                "Cần ghi lý do khi giá trị đối soát chênh lệch");
        repository.insert(normalizedType, normalizedCode, documentValue, checkedValue,
            matched ? "KHOP" : "CHENH_LECH", cleanedNote, actor);
        ReconciliationView saved = get(normalizedType, normalizedCode);
        audit.record(actor, "CREATE", "DOI_SOAT_GIA_TRI", normalizedCode, null, saved);
        return saved;
    }

    private static String type(String value) {
        String result = value == null ? "" : value.trim().toUpperCase(Locale.ROOT);
        if (!result.equals("NHAP") && !result.equals("XUAT"))
            throw new ReconciliationException(Kind.VALIDATION, "INVALID_DOCUMENT_TYPE",
                "Loại chứng từ phải là NHAP hoặc XUAT");
        return result;
    }

    private static String code(String value) {
        String result = value == null ? "" : value.trim().toUpperCase(Locale.ROOT);
        if (!result.matches("[A-Z0-9]{1,6}"))
            throw new ReconciliationException(Kind.VALIDATION, "INVALID_DOCUMENT_CODE",
                "Mã chứng từ không hợp lệ");
        return result;
    }
}
