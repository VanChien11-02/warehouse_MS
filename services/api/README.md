# Spring Boot API

Module backend của hệ thống kho. Bộ khung hiện có Spring Boot 3.5.16, Maven Wrapper, cấu hình SQL Server, health/session endpoint và CRUD danh mục sản phẩm; giao dịch kho chưa được triển khai.

## Công nghệ cố định

- Java 21 LTS.
- Spring Boot 3.x.
- Spring Web, Spring Security.
- Spring JDBC/JdbcTemplate cho stored procedure/function.
- Spring Data JPA cho CRUD phù hợp.
- Microsoft SQL Server JDBC Driver.

## Kiến trúc đề xuất

Tổ chức package-by-feature dưới package gốc của nhóm:

```text
auth/
catalog/
partner/
warehouse/
inbound/
inventory/
outbound/
transfer/
inventorycount/
returning/
reporting/
audit/
```

Các package được gom ownership theo bốn workstream trong [`../../docs/project/governance/WORKSTREAMS.md`](../../docs/project/governance/WORKSTREAMS.md). Package khác chỉ được import public DTO/interface của feature; không import controller, repository, JPA entity hoặc implementation nội bộ.

Các interface liên module và quy ước HTTP đang được thảo luận tại [`../../contracts/BASELINE.md`](../../contracts/BASELINE.md). Ví dụ trong contract chỉ trở thành bắt buộc sau khi tài liệu chuyển sang `Accepted` và chữ ký thật đã compile trong project.

Trước khi khởi tạo package hoặc endpoint, đọc thêm [`../../docs/architecture/MODULE_CATALOG.md`](../../docs/architecture/MODULE_CATALOG.md), [`../../contracts/API_CATALOG.md`](../../contracts/API_CATALOG.md) và [`../../docs/requirements/BUSINESS_RULES.md`](../../docs/requirements/BUSINESS_RULES.md).

Controller chỉ xử lý HTTP/DTO và gọi application service. Application service điều phối transaction/use case. Domain giữ quy tắc thuần. Infrastructure chứa JDBC/JPA/security adapter.

## Chạy và kiểm tra

JDK 21 trở lên phải được gán vào `JAVA_HOME`. Từ root repository, đặt biến môi trường kết nối SQL Server theo [`.env.example`](.env.example). File ví dụ không được tự động nạp; dùng SQL login cục bộ có quyền trên database `BlueStock` hoặc URL tích hợp Windows phù hợp với máy chạy.

SQL Server phải bật TCP/IP tại cổng trong JDBC URL. Kiểm tra bằng `Test-NetConnection 127.0.0.1 -Port 1433` nếu dùng cấu hình mẫu; `sqlcmd -E` thành công qua shared memory không chứng minh JDBC đã kết nối được.

```powershell
$env:SPRING_DATASOURCE_URL = 'jdbc:sqlserver://127.0.0.1:1433;databaseName=BlueStock;encrypt=true;trustServerCertificate=true'
$env:SPRING_DATASOURCE_USERNAME = '<sql-login>'
$env:SPRING_DATASOURCE_PASSWORD = '<local-password>'
pwsh -File scripts/dev.ps1 -Target api
```

Kiểm thử không cần kết nối database cho health/security slice hiện tại:

```powershell
services\api\mvnw.cmd test
```

`GET /api/health` kiểm tra tiến trình; `GET /actuator/health` còn phản ánh tình trạng kết nối DB. Các endpoint khác mặc định bị từ chối cho đến khi module xác thực và quyền được triển khai.

API session hiện có `GET /api/auth/csrf`, `POST /api/auth/dang-nhap`, `GET /api/auth/me` và `POST /api/auth/dang-xuat` theo [`contracts/session-rbac.md`](../../contracts/session-rbac.md). `init.sql` chỉ seed bốn role; cần tạo nhân viên và tài khoản với BCrypt hash qua quy trình quản trị trước khi đăng nhập. Origin frontend mặc định là `http://127.0.0.1:5174`, có thể đổi bằng `APP_WEB_ORIGIN`.

API `/api/san-pham` hỗ trợ danh sách phân trang/tìm kiếm, chi tiết, tạo, sửa tên/giá và xóa khi chưa được tham chiếu theo [`contracts/san-pham.md`](../../contracts/san-pham.md). Loại và đơn vị tính mẫu cho thử nghiệm được tạo bằng `database/seed/catalog_demo.sql`; route ghi yêu cầu `ADMIN` hoặc `QLKHO` và CSRF token.

API `/api/loai-san-pham` và `/api/don-vi-tinh` hỗ trợ CRUD, phân trang/tìm kiếm theo [`contracts/loai-don-vi-tinh.md`](../../contracts/loai-don-vi-tinh.md). Có thể tạo hai dữ liệu này qua API trước khi tạo sản phẩm; không cần seed SQL nếu thử luồng danh mục từ đầu.

Khi database chưa có tài khoản, từ root chạy `pwsh -File scripts/bootstrap-admin.ps1` sau khi đặt biến kết nối JDBC. Lệnh hỏi mật khẩu admin (ít nhất 12 ký tự), tạo tài khoản `admin` với mã `NV0001`/`TK0001` và khởi động API. Dừng tiến trình sau khi tạo xong, rồi chạy `scripts/dev.ps1 -Target api` bình thường. Có thể đổi tên đăng nhập bằng `-Username`; lệnh từ chối chạy lại nếu đã có tài khoản. Mật khẩu không được ghi vào file.

Không commit connection string thật hoặc mật khẩu SQL Server.
