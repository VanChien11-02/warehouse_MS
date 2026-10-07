# Spring Boot API

Module backend của hệ thống kho. Bộ khung hiện có Spring Boot 3.5.16, Maven Wrapper, cấu hình SQL Server, health/session endpoint, CRUD danh mục/đối tác/cấu trúc kho, API nhập/xuất và tra cứu tồn.

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

API session hiện có `GET /api/auth/csrf`, `POST /api/auth/dang-nhap`, `GET /api/auth/me`, `POST /api/auth/dang-xuat` và `PUT /api/auth/doi-mat-khau` theo [`contracts/session-rbac.md`](../../contracts/session-rbac.md). `init.sql` chỉ seed bốn role; cần tạo nhân viên và tài khoản với BCrypt hash qua quy trình quản trị trước khi đăng nhập. Origin frontend mặc định là `http://127.0.0.1:5174`, có thể đổi bằng `APP_WEB_ORIGIN`.

Admin có thể tạo/cập nhật nhân viên, tạo/khóa/mở tài khoản, đổi role và reset mật khẩu qua `/api/nhan-vien` và `/api/tai-khoan` theo [`contracts/identity-admin.md`](../../contracts/identity-admin.md). Mã nhân viên/tài khoản do Admin nhập; endpoint không trả hash.

`GET /api/audit` cho Admin tra cứu nhật ký theo kỳ/tài khoản theo [`contracts/audit.md`](../../contracts/audit.md). Tạo/cập nhật nhân viên, tài khoản và đổi/reset mật khẩu ghi audit trong cùng transaction, không lưu mật khẩu hoặc hash. Ghi audit của chứng từ sẽ được bổ sung vào procedure hoàn tất tương ứng.

API `/api/san-pham` hỗ trợ danh sách phân trang/tìm kiếm, chi tiết, tạo, sửa tên/giá và xóa khi chưa được tham chiếu theo [`contracts/san-pham.md`](../../contracts/san-pham.md). Loại và đơn vị tính mẫu cho thử nghiệm được tạo bằng `database/seed/catalog_demo.sql`; route ghi yêu cầu `ADMIN` hoặc `QLKHO` và CSRF token.

API `/api/loai-san-pham` và `/api/don-vi-tinh` hỗ trợ CRUD, phân trang/tìm kiếm theo [`contracts/loai-don-vi-tinh.md`](../../contracts/loai-don-vi-tinh.md). Có thể tạo hai dữ liệu này qua API trước khi tạo sản phẩm; không cần seed SQL nếu thử luồng danh mục từ đầu.

API `/api/kho`, `/api/khu-vuc` và `/api/vi-tri` hỗ trợ CRUD, phân trang/tìm kiếm và lọc theo kho/khu vực theo [`contracts/warehouse-location.md`](../../contracts/warehouse-location.md). Kiểm tra sức chứa và bảo quản khi ghi sổ tồn thuộc procedure nghiệp vụ.

API `/api/nha-cung-cap` và `/api/doi-tac-nhan-hang` hỗ trợ CRUD, danh sách sản phẩm liên kết và gán/bỏ liên kết theo [`contracts/partner.md`](../../contracts/partner.md). Các liên kết được kiểm tra lại tại thời điểm hoàn tất phiếu.

API `/api/phieu-nhap` đã có danh sách, tạo/sửa/hủy nháp, xem chi tiết và hoàn tất theo [`contracts/inbound-completion.md`](../../contracts/inbound-completion.md). Java tạo/sửa/hủy nháp trong transaction; hoàn tất gọi `sp_HoanTatPhieuNhap` để procedure tự khóa/ghi sổ trong transaction SQL Server. Chỉ `QLKHO` được hoàn tất. Cần tạo nhà cung cấp và mapping sản phẩm trước khi hoàn tất.

API `GET /api/ton-kho` đọc `vw_TonKhoChiTiet`, hỗ trợ lọc/phân trang và chỉ lấy tồn khả dụng theo [`contracts/inventory-query.md`](../../contracts/inventory-query.md). Chưa có API ghi tồn trực tiếp; xuất kho vẫn phải kiểm tra lại trong transaction.

API `/api/phieu-xuat` đã có danh sách, tạo/sửa/hủy nháp, xem chi tiết và hoàn tất theo [`contracts/outbound-fefo-completion.md`](../../contracts/outbound-fefo-completion.md). Procedure kiểm tra FEFO và trừ tồn trong transaction SQL Server. Chỉ `QLKHO` được hoàn tất. Cần tạo đối tác nhận và mapping sản phẩm trước khi hoàn tất.

`GET /api/phieu-xuat/{maPhieuXuat}/goi-y-fefo` đề xuất lô/vị trí cho một sản phẩm và số lượng, trả phần thiếu nếu tồn không đủ. Gợi ý không giữ chỗ; lúc hoàn tất procedure kiểm tra FEFO và tồn lần nữa.

`GET /api/bao-cao/nhap-xuat` trả báo cáo theo kỳ, kho và sản phẩm từ sổ biến động đã ghi cùng transaction nhập/xuất; đơn giá lấy từ phiếu nhập của lô theo [`contracts/reporting.md`](../../contracts/reporting.md). `GET /api/bao-cao/chenh-lech-kiem-ke` chỉ lấy dòng chênh lệch của phiếu đã hoàn tất theo [`contracts/count-discrepancy-report.md`](../../contracts/count-discrepancy-report.md). `GET /api/bao-cao/lo-sap-het-han` lọc tồn còn hạn theo [`contracts/expiry-report.md`](../../contracts/expiry-report.md).

API `/api/phieu-chuyen` có danh sách, tạo/sửa/hủy nháp, xem chi tiết và hoàn tất theo [`contracts/transfer.md`](../../contracts/transfer.md). Procedure kiểm tra tồn nguồn, sức chứa, bảo quản và ghi hai phía chuyển trong transaction; chỉ `QLKHO` được hoàn tất.

API `/api/phieu-kiem-ke` tạo snapshot tồn theo vị trí, cho nhập số đếm theo lô, xem danh sách/chi tiết, hủy nháp và hoàn tất theo [`contracts/inventory-count.md`](../../contracts/inventory-count.md). Procedure kiểm tra snapshot còn mới, lý do chênh lệch và các ràng buộc vị trí trước khi điều chỉnh tồn/ghi sổ trong một transaction; chỉ `QLKHO` được hoàn tất.

API `/api/phieu-tra-hang` có danh sách, tạo/sửa/hủy nháp từ phiếu xuất đã hoàn tất, xem chi tiết và hoàn tất theo [`contracts/returning.md`](../../contracts/returning.md). Procedure kiểm tra tổng lượng đã trả, vị trí hàng tốt/hỏng và ghi sổ trong transaction; chỉ `QLKHO` được hoàn tất.

Khi database chưa có tài khoản, từ root chạy `pwsh -File scripts/bootstrap-admin.ps1` sau khi đặt biến kết nối JDBC. Lệnh hỏi mật khẩu admin (ít nhất 12 ký tự), tạo tài khoản `admin` với mã `NV0001`/`TK0001` và khởi động API. Dừng tiến trình sau khi tạo xong, rồi chạy `scripts/dev.ps1 -Target api` bình thường. Có thể đổi tên đăng nhập bằng `-Username`; lệnh từ chối chạy lại nếu đã có tài khoản. Mật khẩu không được ghi vào file.

Không commit connection string thật hoặc mật khẩu SQL Server.
