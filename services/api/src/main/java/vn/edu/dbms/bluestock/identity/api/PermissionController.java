package vn.edu.dbms.bluestock.identity.api;

import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import vn.edu.dbms.bluestock.identity.application.PermissionService;
import vn.edu.dbms.bluestock.identity.application.PermissionService.RolePermissions;

@RestController
@RequestMapping("/api/quyen-han")
public class PermissionController {
    private final PermissionService service;

    public PermissionController(PermissionService service) {
        this.service = service;
    }

    @GetMapping
    public List<RolePermissions> list() {
        return service.list();
    }
}
