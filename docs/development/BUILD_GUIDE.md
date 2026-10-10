# Hướng dẫn build và khởi tạo dự án

Tài liệu này mô tả hiện trạng chạy được và thứ tự kỹ thuật để hoàn thiện hệ thống. Đây không phải lịch sprint; các workstream có thể phát triển song song bằng contract/stub.

## 1. Yêu cầu môi trường

| Công cụ | Phiên bản |
| --- | --- |
| Git | 2.40 trở lên |
| PowerShell | 7 trở lên |
| Node.js | 22 trở lên (`.nvmrc`) |
| JDK | 21 trở lên; `JAVA_HOME` trỏ tới JDK |
| SQL Server | 2022 Developer hoặc Express |
| SQL client | SSMS hoặc Azure Data Studio |

Kiểm tra môi trường:

```powershell
pwsh -File scripts/setup.ps1
```

Không cài dependency hoặc công nghệ khác để thay thế stack đã chốt nếu chưa có ADR.

## 2. Chạy phần đang có

Frontend static:

```powershell
pwsh -File scripts/dev.ps1 -Target web
```

Mở `http://127.0.0.1:5174`.

Cổng kiểm tra root:

```powershell
pwsh -File scripts/verify.ps1
```

Backend đã có Maven Wrapper, health/session endpoint, CRUD sản phẩm và test; giao dịch kho chưa có. Database đã có `init.sql` dựng chín bảng identity/danh mục/cấu trúc kho; các bảng và object nghiệp vụ còn lại thuộc `DB-01` chưa hoàn tất.

## 3. Cấu hình local

Dùng biến môi trường cho kết nối SQL Server; không commit secret:

```text
SPRING_DATASOURCE_URL
SPRING_DATASOURCE_USERNAME
SPRING_DATASOURCE_PASSWORD
```

Repository chỉ được chứa `.env.example` hoặc `application-*.example.*` với giá trị giả. Không commit password, token hoặc connection string thật.

Mẫu biến môi trường nằm tại [`../../services/api/.env.example`](../../services/api/.env.example); Spring Boot không tự nạp file này. Gán các biến trong terminal trước khi chạy API. `GET /api/health` kiểm tra tiến trình, còn `GET /actuator/health` phản ánh cả kết nối DB.

JDBC cần SQL Server bật TCP/IP và lắng nghe cổng trong `SPRING_DATASOURCE_URL` (mẫu dùng 1433). Bật TCP/IP bằng SQL Server Configuration Manager, khởi động lại instance rồi kiểm tra `Test-NetConnection 127.0.0.1 -Port 1433`. `sqlcmd -E` trên cùng máy có thể dùng shared memory dù TCP/IP đang tắt, nên kết quả test SQL không thay thế kiểm tra kết nối JDBC. Tạo SQL login cục bộ với quyền trên `BlueStock`, đặt username/password qua biến môi trường; không ghi chúng vào repository.

Sau khi dựng database, chạy `pwsh -File scripts/bootstrap-admin.ps1` đúng một lần khi bảng tài khoản còn trống. Lệnh yêu cầu mật khẩu tại terminal, lưu BCrypt hash và khởi động API. Dừng tiến trình bootstrap rồi chạy `pwsh -File scripts/dev.ps1 -Target api` với cấu hình JDBC thông thường.

Để thử API sản phẩm trên database sạch, chạy `sqlcmd -S localhost -E -C -b -d BlueStock -i database/seed/catalog_demo.sql`. Seed này chỉ tạo loại `LSP001` và đơn vị `DVT001`, có thể chạy lại; sản phẩm được tạo qua API theo `contracts/san-pham.md`.

Database `BlueStock`/`dbo`, session cookie và runner `sqlcmd` đã được quyết định tại ADR 0003. CORS cho frontend và migration tool sau baseline sẽ được quyết định khi triển khai phần tương ứng.

## 4. Thứ tự kỹ thuật tối thiểu

### Bước A - Khóa context và contract

- Giải quyết các mục P0 trong [`../project/governance/OPEN_DECISIONS.md`](../project/governance/OPEN_DECISIONS.md).
- Chuyển [`../../contracts/BASELINE.md`](../../contracts/BASELINE.md) sang `Accepted` khi đủ điều kiện.
- Chốt owner/reviewer và tạo branch workstream từ cùng commit.

### Bước B - Database baseline

- Tạo thư mục/object theo [`../../database/SCHEMA_PLAN.md`](../../database/SCHEMA_PLAN.md).
- Viết `database/init.sql` dựng database sạch theo đúng thứ tự.
- Thêm seed giả tối thiểu cho role, tài khoản demo, danh mục, kho/vị trí và đối tác.
- Thêm test constraint và test script chạy lại từ database sạch.

### Bước C - Spring Boot shell

- Tạo Maven project Java 21 + Spring Boot 3.x và commit Maven Wrapper.
- Thêm dependencies: Web, Validation, Security, JDBC, JPA, SQL Server driver và test phù hợp.
- Thêm health endpoint, error envelope, pagination và cấu hình mẫu không chứa secret.
- Tạo package-by-feature theo module catalog.
- Nối `mvnw.cmd test` vào `scripts/verify.ps1` nếu chưa được tự động phát hiện.

### Bước D - Vertical slices nền tảng

Làm các lát dọc nhỏ, mỗi lát có schema + backend + contract + UI/test:

1. Session/RBAC và current user.
2. Sản phẩm/đơn vị tính/loại sản phẩm.
3. Kho/khu vực/vị trí.
4. Nhà cung cấp/đối tác.

### Bước E - Luồng kho cốt lõi

1. Phiếu nhập nháp → hoàn tất → lô → put-away → tồn.
2. Tra cứu tồn theo sản phẩm/lô/vị trí.
3. Phiếu xuất → gợi ý FEFO → hoàn tất → trừ tồn.
4. Báo cáo nhập-xuất-tồn.

### Bước F - Kiểm soát và hoàn thiện

- Chuyển kho.
- Kiểm kê/điều chỉnh.
- Trả hàng.
- Audit, concurrency, index/performance và kịch bản demo.

## 5. Lệnh mục tiêu sau khi khởi tạo đủ

Database hiện có thể dựng phần nền tảng từ root repository bằng `sqlcmd`:

```powershell
sqlcmd -S localhost -E -C -b -i database/init.sql
pwsh -File scripts/verify.ps1 -WithDatabase
```

Backend:

```powershell
services\api\mvnw.cmd test
services\api\mvnw.cmd spring-boot:run
```

Frontend:

```powershell
pwsh -File scripts/dev.ps1 -Target web
```

Full gate:

```powershell
pwsh -File scripts/verify.ps1
```

`init.sql` chỉ nhận database sạch và dừng nếu `BlueStock` đã tồn tại. Khi dùng instance khác, thay `localhost` bằng địa chỉ phù hợp.

## 6. Seed và tài khoản demo

Seed cần đủ cho một kịch bản demo nhưng không chứa dữ liệu thật:

- bốn role;
- ít nhất một tài khoản giả cho mỗi role;
- mật khẩu demo được hash và password rõ chỉ ghi trong hướng dẫn demo cục bộ, không dùng lại ở môi trường thật;
- loại sản phẩm, đơn vị tính và vài sản phẩm;
- nhà cung cấp, đối tác nhận hàng;
- một kho, nhiều khu vực/vị trí;
- lô có hạn dùng khác nhau để chứng minh FEFO.

Giá trị tài khoản/password demo cụ thể: **Cần chốt**.

## 7. Checklist build sạch

- [ ] Clone mới hoặc checkout sạch.
- [ ] `scripts/setup.ps1` đạt.
- [ ] Database được dựng bằng một điểm vào duy nhất.
- [ ] Seed chạy thành công và không chứa secret/dữ liệu thật.
- [ ] Backend test đạt và health endpoint trả thành công.
- [ ] Frontend chạy ở port đã tài liệu hóa và gọi đúng API adapter.
- [ ] E2E nhập → tồn → xuất → báo cáo đạt.
- [ ] Test rollback và hoàn tất lặp đạt.
- [ ] Test role và concurrency có bằng chứng.
- [ ] `scripts/verify.ps1` đạt từ root.

## 8. Xử lý lỗi thường gặp

| Hiện tượng | Kiểm tra |
| --- | --- |
| Frontend mở được nhưng toàn dữ liệu demo | Kiểm tra `USE_DUMMY_DATA` và API adapter; không sửa URL rải rác trong UI |
| CORS bị chặn | Kiểm tra origin chính xác `127.0.0.1`/`localhost` và cấu hình Spring Security |
| Backend chưa chạy | Xác nhận `services/api/mvnw.cmd` đã tồn tại và JDK là 21+ |
| SQL script chạy sai thứ tự | Chạy qua `database/init.sql`, không chạy ngẫu nhiên từng file phụ thuộc |
| Hoàn tất phiếu hai lần làm tăng/giảm tồn | Kiểm tra trạng thái và khóa nằm trong cùng transaction |
| Merge xung đột frontend | Hoàn thành `GOV-03`, không để mọi feature tiếp tục sửa chung `app.js`/`styles.css` lớn |

## 9. Handoff

Mỗi lần bàn giao phải ghi:

- module/file đã đổi;
- contract/schema có thay đổi hay không;
- lệnh đã chạy và kết quả thật;
- phần chưa chạy được và nguyên nhân;
- quyết định/rủi ro còn mở.
