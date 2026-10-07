# Hướng dẫn build và khởi tạo dự án

Tài liệu này hướng dẫn dựng database sạch, chạy API và kiểm tra từng lớp. Contract tổng thể vẫn ở trạng thái Draft; xem backlog để biết các hạng mục cần nhóm review.

## 1. Yêu cầu môi trường

| Công cụ | Phiên bản |
| --- | --- |
| Git | 2.40 trở lên |
| PowerShell | 7 trở lên |
| Node.js | 22 trở lên (`.nvmrc`) |
| JDK | 21 trở lên; `JAVA_HOME` trỏ tới JDK |
| SQL Server | 2022 Developer hoặc Express (mục tiêu dự án) |
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

Backend đã có session/RBAC, CRUD danh mục/kho/đối tác, năm luồng chứng từ, tồn, báo cáo và audit. `database/init.sql` dựng 27 bảng cùng procedure, function, view, trigger, index và bốn database role. Frontend có chế độ API cho sản phẩm, tra cứu tồn và báo cáo nhập–xuất–tồn; các màn hình khác vẫn dùng dữ liệu mẫu.

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

Nếu instance chỉ cho Windows Authentication, bật chế độ SQL Server and Windows Authentication trong cấu hình instance rồi khởi động lại dịch vụ. Có thể dùng login SQL có sẵn hoặc tạo login kỹ thuật riêng cho bản demo trong SSMS. Trên database demo, gán user của login đó vào `db_owner` để API chạy các use case; đây là quyền của kết nối kỹ thuật, không thay cho bốn role ứng dụng. Bốn role SQL dùng khi truy cập database trực tiếp được mô tả trong [`../../database/security/README.md`](../../database/security/README.md). Giữ mật khẩu login ngoài repository và không dùng tài khoản demo cho dữ liệu thật.

Ví dụ chạy trong SSMS sau khi thay mật khẩu giữ riêng ở máy:

```sql
CREATE LOGIN [bluestock_api_local] WITH PASSWORD = '<mat-khau-rieng-du-manh>';
GO
USE [BlueStock];
CREATE USER [bluestock_api_local] FOR LOGIN [bluestock_api_local];
ALTER ROLE [db_owner] ADD MEMBER [bluestock_api_local];
```

Đặt `SPRING_DATASOURCE_USERNAME=bluestock_api_local` và `SPRING_DATASOURCE_PASSWORD` bằng mật khẩu vừa tạo trong terminal chạy API. Nếu login/user đã có, dùng tài khoản hiện tại thay vì chạy lại lệnh `CREATE`.

Sau khi dựng database, chạy `pwsh -File scripts/bootstrap-admin.ps1` đúng một lần khi bảng tài khoản còn trống. Lệnh yêu cầu mật khẩu tại terminal, lưu BCrypt hash và khởi động API. Dừng tiến trình bootstrap rồi chạy `pwsh -File scripts/dev.ps1 -Target api` với cùng cấu hình JDBC.

Seed `database/seed/demo.sql` tạo danh mục, đối tác, kho/vị trí và phiếu nhập đã hoàn tất với ba lô, 40 đơn vị tồn; có thể chạy lại mà không ghi sổ hai lần. Seed không tạo tài khoản hoặc mật khẩu. Nếu chỉ cần danh mục trống để thử CRUD, dùng `database/seed/catalog_demo.sql` thay cho seed đầy đủ.

Database `BlueStock`/`dbo`, session cookie và runner `sqlcmd` theo ADR 0003. Origin frontend mặc định trong API là `http://127.0.0.1:5174`; có thể đổi bằng `APP_WEB_ORIGIN`. Frontend dùng adapter theo contract cho sản phẩm, tồn kho và báo cáo nhập–xuất–tồn.

## 4. Dựng database sạch và seed

Từ root repository, trên SQL Server chưa có database `BlueStock`:

```powershell
sqlcmd -S localhost -E -C -b -i database/init.sql
sqlcmd -S localhost -E -C -b -d BlueStock -i database/seed/demo.sql
```

`init.sql` dừng nếu `BlueStock` đã tồn tại; không xóa database cũ. `demo.sql` có thể chạy lại. Nếu dùng tên instance khác, thay `localhost`. Xem [`../../database/README.md`](../../database/README.md) để nâng cấp database local cũ bằng migration.

## 5. Chạy API và kiểm tra

Sau khi đặt các biến JDBC ở mục 3, chạy bootstrap ở terminal riêng. Khi thấy API khởi động, dừng tiến trình đó và chạy lại bình thường:

```powershell
pwsh -File scripts/bootstrap-admin.ps1
pwsh -File scripts/dev.ps1 -Target api
```

Kiểm tra `GET http://127.0.0.1:8080/api/health` và `GET http://127.0.0.1:8080/actuator/health`. Endpoint thứ hai phải phản ánh kết nối database. Quy trình đăng nhập, CSRF và quyền nằm ở [`../../contracts/session-rbac.md`](../../contracts/session-rbac.md). Tài khoản cho ba role còn lại được Admin tạo qua [`../../contracts/identity-admin.md`](../../contracts/identity-admin.md). Kịch bản Postman nhập → tồn → xuất FEFO → báo cáo nằm ở [`../testing/API_SMOKE.md`](../testing/API_SMOKE.md).

Mở frontend static ở terminal khác:

```powershell
pwsh -File scripts/dev.ps1 -Target web
```

Giao diện mặc định trình bày dữ liệu mẫu. Mở `http://127.0.0.1:5174/?mode=api#products` để thử CRUD sản phẩm, `?mode=api#inventory` để tra cứu tồn hoặc `?mode=api#reports` để xem báo cáo với session thật; các màn hình khác chưa nối API. Để thử nghiệp vụ chứng từ, dùng HTTP client theo contract. Không dùng form demo làm bằng chứng E2E backend.

Nếu port 5174 hoặc 8080 đã có ứng dụng khác sử dụng, chạy web bằng `pwsh -File scripts/dev.ps1 -Target web -Port 5176`, đặt `APP_WEB_ORIGIN=http://127.0.0.1:5176` và `SERVER_PORT=8082` trong terminal API, rồi mở `http://127.0.0.1:5176/?mode=api&apiPort=8082#products`. Origin phải khớp chính xác để cookie session và CORS hoạt động.

Trước khi bàn giao, chạy hai cổng kiểm tra:

```powershell
pwsh -File scripts/verify.ps1
pwsh -File scripts/verify.ps1 -WithDatabase -WithConcurrency
```

`verify.ps1` mặc định chỉ chạy kiểm tra file, JavaScript, liên kết Markdown và test Java. Tham số `-WithDatabase` chạy thêm 23 script SQL trên database được chọn; `-WithConcurrency` thêm bài tranh chấp hai session. Có thể dùng `-DatabaseName <ten_database>` cho database thử riêng. Cổng này không thay thế E2E HTTP hay xác nhận trên SQL Server 2022.

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
