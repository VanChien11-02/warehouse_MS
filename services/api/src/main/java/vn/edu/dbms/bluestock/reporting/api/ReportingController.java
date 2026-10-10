package vn.edu.dbms.bluestock.reporting.api;

import java.time.LocalDate;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import vn.edu.dbms.bluestock.reporting.application.ReportingModels.MovementReportPage;
import vn.edu.dbms.bluestock.reporting.application.ReportingModels.CountDiscrepancyPage;
import vn.edu.dbms.bluestock.reporting.application.ReportingService;

@RestController
@RequestMapping("/api/bao-cao")
public class ReportingController {
    private final ReportingService service;

    public ReportingController(ReportingService service) {
        this.service = service;
    }

    @GetMapping("/nhap-xuat")
    public MovementReportPage movementReport(
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate tuNgay,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate denNgay,
        @RequestParam(required = false) String maKho,
        @RequestParam(required = false) String maSanPham,
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size) {
        return service.movementReport(tuNgay, denNgay, maKho, maSanPham, page, size);
    }

    @GetMapping("/chenh-lech-kiem-ke")
    public CountDiscrepancyPage countDiscrepancies(
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate tuNgay,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate denNgay,
        @RequestParam(required = false) String maKho,
        @RequestParam(required = false) String maViTri,
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size) {
        return service.countDiscrepancies(tuNgay, denNgay, maKho, maViTri, page, size);
    }
}
