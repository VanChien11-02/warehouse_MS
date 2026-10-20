package vn.edu.dbms.bluestock.inventory.application;

import java.time.LocalDate;
import java.util.List;

public interface AvailableStockQuery {
    List<StockCandidate> findAvailable(String productCode, String warehouseCode, LocalDate businessDate);

    record StockCandidate(String maLo, String maViTri, int soLuongTon, LocalDate hanSuDung) {}
}
