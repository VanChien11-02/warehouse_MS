# Kết quả kiểm chứng local

Ngày 2026-10-08, nhánh `feature/db-foundation`, commit `83e69f5`. Môi trường: Windows, PowerShell 7.6.5, Node.js 25.9.0, JDK 25, SQL Server 2025 Express 17.0.1135.8. Mã Java biên dịch với target Java 21; chưa chạy trên JDK 21 hoặc SQL Server 2022.

| Lệnh/kiểm tra | Kết quả |
| --- | --- |
| `pwsh -File scripts/setup.ps1` với `JAVA_HOME` trỏ JDK 25 | Exit 0; kiểm tra Git, PowerShell, Node, Java đạt |
| `pwsh -File scripts/verify.ps1` | Exit 0 sau khi thêm form nhập/xuất; 8 test frontend và 156 test Java, không lỗi/bỏ qua; kiểm tra cú pháp frontend và liên kết Markdown đạt |
| `pwsh -File scripts/verify.ps1 -WithDatabase -WithConcurrency -DatabaseName BlueStockBuildCheck2` | Exit 0 sau khi thêm tồn kho; 6 test frontend, 156 test Java, 23 script SQL và bài hai session xuất cạnh tranh đạt |
| `services/api/mvnw.cmd -q -DskipTests package` | Exit 0; tạo `bluestock-api-0.1.0-SNAPSHOT.jar` |
| Static server ở port 5175: `GET /`, `/app.js`, `/core/navigation.js`, `/data/demo.js` | Cả bốn trả HTTP 200 |
| Chrome headless với web port 5176 và API giả lập cục bộ port 8081 | Chế độ demo và API render; danh sách sản phẩm, tạo, sửa, xóa; tra cứu tồn, lọc và làm mới qua adapter đạt |
| Spring Boot trên port 8082, SQL Server TCP port 1433, database thử `BlueStockHttpCheck` | `GET /actuator/health` trả `UP`; đăng nhập Admin, tạo tài khoản `QLKHO`, nhập 4 đơn vị, xem tồn/lô mới, gợi ý và hoàn tất xuất FEFO 2 đơn vị, báo cáo một dòng đạt. Tồn `SP0001` từ 30 thành 32; hoàn tất xuất lần hai trả `409 OUTBOUND_NOT_DRAFT`, xuất sai thứ tự trả `409 FEFO_VIOLATION`, cả hai giữ nguyên tồn |
| Chrome headless với web port 5176 và API thật port 8082 | Đăng nhập `QLKHO`, tạo/sửa/xóa sản phẩm, tạo/hoàn tất `PN0002` tạo lô `LO0005`, tra cứu tồn, tạo `PX0003`, lấy gợi ý FEFO, hoàn tất xuất và xem báo cáo đạt qua session cookie, CSRF và CORS |
| `database/seed/demo.sql` trên database sạch và chạy lại | Exit 0; ba lô, 40 đơn vị tồn; lần chạy lại không cộng tồn |

`BlueStockBuildCheck2` là database thử riêng được dựng từ bản sao `database/init.sql` chỉ thay tên `BlueStock` để không ghi đè database local. Các script SQL test dùng Windows Authentication qua `sqlcmd`. Bài HTTP dùng database `BlueStockHttpCheck` dựng và seed riêng; tạo SQL login tạm, bootstrap Admin với mật khẩu sinh trong bộ nhớ, chạy API và kiểm tra theo [`API_SMOKE.md`](API_SMOKE.md), sau đó xóa database và login tạm. Không lưu mật khẩu, cookie hoặc token trong repository.

SQL Server instance `MSSQLSERVER` đã được khởi động lại sau khi bật TCP/IP; `Test-NetConnection 127.0.0.1 -Port 1433` và `sqlcmd -S tcp:127.0.0.1,1433 -E -C` đều đạt. Docker Desktop đang dùng port 8080 và 5174 trên máy thử, nên bài HTTP dùng `SERVER_PORT=8082`, web dùng port 5176 và API dùng `APP_WEB_ORIGIN=http://127.0.0.1:5176`. Chưa xác nhận trên JDK 21 hoặc SQL Server 2022. Chế độ API frontend hỗ trợ sản phẩm, phiếu nhập/xuất một dòng, tồn kho và báo cáo nhập–xuất–tồn; các màn hình khác còn dùng dữ liệu demo.

## Compose trên SQL Server 2022 (2026-10-09)

Môi trường: Docker Desktop Linux containers, image `mcr.microsoft.com/mssql/server:2022-latest` báo SQL Server 2022 CU27 16.0.4295.3; image API chạy Eclipse Temurin 21.0.12.1. Mật khẩu được sinh local trong `.env` Git bỏ qua. Host chạy bộ test Maven bằng JDK 25 do không có JDK 21 cài trực tiếp.

| Lệnh/kiểm tra | Kết quả |
| --- | --- |
| `docker compose config --quiet` và `docker compose build api web` | Exit 0; image API biên dịch target Java 21 |
| `docker compose up -d --no-build`, `docker compose ps --all` | DB `healthy`, `db-init` exit 0, API/web `Up` |
| `GET /actuator/health`, `GET /` web | `UP`, HTTP 200 |
| Đăng nhập admin qua session/CSRF và `GET /api/ton-kho?maSanPham=SP0001` | Role `ADMIN`, trả hai lô demo của sản phẩm |
| `docker compose down` rồi `docker compose up -d --no-build` | Volume giữ ba lô/40 đơn vị tồn và một tài khoản; seed/bootstrap không ghi thêm |
| `pwsh -File scripts/verify.ps1 -WithDatabase -WithConcurrency -SqlServer 'tcp:127.0.0.1,14330' -SqlUser bluestock_app` với `SQLCMDPASSWORD` từ `.env` | Exit 0: 8 test frontend, 157 test Java, 23 script SQL và bài hai session xuất cạnh tranh |
| `node "$env:TEMP\bluestock-http-smoke.mjs"` với `SMOKE_BASE_URL=http://127.0.0.1:8080` và mật khẩu admin local; client tạm thực hiện [`API_SMOKE.md`](API_SMOKE.md) | Exit 0: Admin/QLKHO đăng nhập; nhập `PN0001` tạo lô `LO0063`; xuất `PX0001`; tồn `SP0001` từ 30 thành 32; hoàn tất lại trả `409 OUTBOUND_NOT_DRAFT`; xuất sai FEFO trả `409 FEFO_VIOLATION` và giữ tồn; báo cáo có một dòng |

Runner SQL dùng UTF-8 khi đọc script bằng Windows `sqlcmd`, và bài concurrency lấy giờ hẹn từ SQL Server để không phụ thuộc múi giờ máy host/container. Client HTTP tạm nằm ngoài repository; kịch bản có thể lặp lại thủ công theo [`API_SMOKE.md`](API_SMOKE.md). Không lưu secret hoặc session trong repository.
