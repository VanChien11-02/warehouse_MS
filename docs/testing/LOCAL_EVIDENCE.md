# Kết quả kiểm chứng local

Ngày 2026-10-08, nhánh `feature/db-foundation`, commit `af83120`. Môi trường: Windows, PowerShell 7.6.5, Node.js 25.9.0, JDK 25, SQL Server 2025 Express 17.0.1135.8. Mã Java biên dịch với target Java 21; chưa chạy trên JDK 21 hoặc SQL Server 2022.

| Lệnh/kiểm tra | Kết quả |
| --- | --- |
| `pwsh -File scripts/setup.ps1` với `JAVA_HOME` trỏ JDK 25 | Exit 0; kiểm tra Git, PowerShell, Node, Java đạt |
| `pwsh -File scripts/verify.ps1` | Exit 0; 5 test frontend và 156 test Java, không lỗi/bỏ qua; kiểm tra cú pháp frontend và liên kết Markdown đạt |
| `pwsh -File scripts/verify.ps1 -WithDatabase -WithConcurrency -DatabaseName BlueStockBuildCheck2` | Exit 0; 5 test frontend, 156 test Java, 23 script SQL và bài hai session xuất cạnh tranh đạt |
| `services/api/mvnw.cmd -q -DskipTests package` | Exit 0; tạo `bluestock-api-0.1.0-SNAPSHOT.jar` |
| Static server ở port 5175: `GET /`, `/app.js`, `/core/navigation.js`, `/data/demo.js` | Cả bốn trả HTTP 200 |
| Chrome headless với web port 5176 và API giả lập cục bộ port 8081 | Chế độ demo và API render; danh sách sản phẩm, tạo, sửa và xóa qua adapter đạt |
| `database/seed/demo.sql` trên database sạch và chạy lại | Exit 0; ba lô, 40 đơn vị tồn; lần chạy lại không cộng tồn |

`BlueStockBuildCheck2` là database thử riêng được dựng từ bản sao `database/init.sql` chỉ thay tên `BlueStock` để không ghi đè database local. Các script SQL test dùng Windows Authentication qua `sqlcmd`. Database demo và script không chứa tài khoản đăng nhập ứng dụng; phải bootstrap Admin trước khi thử HTTP.

Chưa xác nhận API HTTP/JDBC hoặc kịch bản [`API_SMOKE.md`](API_SMOKE.md): SQL Server instance `MSSQLSERVER` trên máy này có TCP/IP `Enabled=0`, `Test-NetConnection 127.0.0.1 -Port 1433` trả `False`. `sqlcmd -E` vẫn kết nối qua shared memory. Sau khi bật TCP/IP và khởi động lại dịch vụ, cần chạy kịch bản HTTP rồi lưu status/tồn/báo cáo trước-sau. Port 8080 hiện do Docker Desktop dùng; nếu chạy API ở port khác, dùng `SERVER_PORT` và tham số `apiPort` của frontend. Chế độ API frontend mới hỗ trợ sản phẩm; các màn hình khác còn dùng dữ liệu demo.
