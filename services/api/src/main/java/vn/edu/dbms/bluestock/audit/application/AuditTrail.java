package vn.edu.dbms.bluestock.audit.application;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
public class AuditTrail {
    private final JdbcTemplate jdbc;
    private final ObjectMapper mapper;

    public AuditTrail(JdbcTemplate jdbc, ObjectMapper mapper) {
        this.jdbc = jdbc;
        this.mapper = mapper;
    }

    public void record(String actor, String action, String table, String code,
        Object before, Object after) {
        jdbc.update("""
            INSERT INTO dbo.LICH_SU_THAO_TAC
                (MaTK, HanhDong, TenBang, MaBanGhi, DuLieuCu, DuLieuMoi)
            VALUES (?, ?, ?, ?, ?, ?)
            """, actor, action, table, code, json(before), json(after));
    }

    private String json(Object value) {
        if (value == null) return null;
        try {
            return mapper.writeValueAsString(value);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Không thể ghi dữ liệu audit", exception);
        }
    }
}
