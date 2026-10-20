package vn.edu.dbms.bluestock.audit.infrastructure;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;
import vn.edu.dbms.bluestock.audit.application.AuditModels.AuditPage;
import vn.edu.dbms.bluestock.audit.application.AuditModels.AuditView;

@Repository
public class AuditJdbcRepository {
    private final NamedParameterJdbcTemplate jdbc;

    public AuditJdbcRepository(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public AuditPage findPage(LocalDate from, LocalDate through,
        LocalDateTime startUtc, LocalDateTime endUtc, String actor, int page, int size) {
        var params = new MapSqlParameterSource()
            .addValue("startUtc", startUtc).addValue("endUtc", endUtc);
        String where = "WHERE ThoiGian >= :startUtc AND ThoiGian < :endUtc ";
        if (actor != null) {
            where += "AND MaTK = :actor ";
            params.addValue("actor", actor);
        }
        Long count = jdbc.queryForObject("SELECT COUNT_BIG(*) FROM dbo.LICH_SU_THAO_TAC " + where,
            params, Long.class);
        long total = count == null ? 0 : count;
        params.addValue("offset", page * size).addValue("size", size);
        List<AuditView> items = jdbc.query("""
            SELECT MaLichSu, MaTK, ThoiGian, HanhDong, TenBang, MaBanGhi,
                   DuLieuCu, DuLieuMoi
            FROM dbo.LICH_SU_THAO_TAC
            """ + where + "ORDER BY ThoiGian DESC, MaLichSu DESC "
            + "OFFSET :offset ROWS FETCH NEXT :size ROWS ONLY", params,
            (row, index) -> new AuditView(row.getLong("MaLichSu"),
                row.getString("MaTK").trim(),
                row.getObject("ThoiGian", LocalDateTime.class).atOffset(ZoneOffset.UTC),
                row.getString("HanhDong"), row.getString("TenBang"),
                row.getString("MaBanGhi").trim(),
                row.getString("DuLieuCu"), row.getString("DuLieuMoi")));
        return new AuditPage(from, through, items, page, size,
            total, (total + size - 1) / size);
    }
}
