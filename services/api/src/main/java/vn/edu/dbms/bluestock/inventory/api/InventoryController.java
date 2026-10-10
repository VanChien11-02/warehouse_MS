package vn.edu.dbms.bluestock.inventory.api;

import java.time.LocalDate;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import vn.edu.dbms.bluestock.inventory.application.InventoryModels.StockFilter;
import vn.edu.dbms.bluestock.inventory.application.InventoryModels.StockPage;
import vn.edu.dbms.bluestock.inventory.application.InventoryService;

@RestController
@RequestMapping("/api/ton-kho")
public class InventoryController {
    private final InventoryService service;

    public InventoryController(InventoryService service) {
        this.service = service;
    }

    @GetMapping
    public StockPage list(@RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size,
        @RequestParam(required = false) String maKho,
        @RequestParam(required = false) String maViTri,
        @RequestParam(required = false) String maSanPham,
        @RequestParam(required = false) String maLo,
        @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate hanSuDungTruoc,
        @RequestParam(defaultValue = "false") boolean chiKhaDung) {
        return service.list(page, size, new StockFilter(maKho, maViTri, maSanPham,
            maLo, hanSuDungTruoc, chiKhaDung));
    }
}
