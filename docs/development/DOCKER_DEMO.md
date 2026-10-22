# Demo bằng Docker Compose

Compose dựng SQL Server 2022 Developer, khởi tạo `BlueStock`, chạy Spring Boot trên Java 21 và phục vụ frontend tĩnh. Cần Docker Desktop ở chế độ Linux containers và đủ tài nguyên cho SQL Server. Chạy các lệnh từ root repository.

## Khởi động

```powershell
Copy-Item .env.example .env
```

Điền ba mật khẩu **khác nhau** vào `.env`: `MSSQL_SA_PASSWORD`, `APP_DB_PASSWORD`, `APP_ADMIN_PASSWORD`. Mật khẩu SQL cần đáp ứng chính sách phức tạp của SQL Server. `APP_DB_PASSWORD` dài 12–64 ký tự và chỉ dùng chữ, số hoặc `@#%+=._!-`. `APP_ADMIN_PASSWORD` dài ít nhất 12 ký tự. `.env` đã được Git bỏ qua; không chia sẻ file này.

```powershell
docker compose up -d --build
docker compose ps --all
Invoke-RestMethod http://127.0.0.1:8080/actuator/health
```

Đợi `db` ở trạng thái `healthy`, `db-init` kết thúc với mã `0`, `api` và `web` ở trạng thái `Up`, và health trả `UP`. Mở `http://127.0.0.1:5174/?mode=api#accounts`, đăng nhập `admin` bằng `APP_ADMIN_PASSWORD` trong `.env`; Admin sẽ thấy quản lý nhân viên và tài khoản. Trang không có `?mode=api` là prototype dùng dữ liệu mẫu. Các vai trò kho/kế toán thấy những màn API được cấp quyền. Sau khi build lại web, tải lại tab đang mở để nhận JavaScript mới; container web gửi `Cache-Control: no-store` để tránh giữ phiên bản cũ khi tải lại.

Compose tạo tài khoản admin **chỉ khi bảng tài khoản trống**. Đổi `APP_ADMIN_PASSWORD` sau lần khởi tạo không đổi mật khẩu trong database đã tồn tại. `db-init` chạy seed giả lập theo cách lặp lại được, không ghi sổ thêm khi khởi động lại.

## Kết nối SQL Server và kiểm tra

SQL Server được xuất trên máy chủ tại `tcp:127.0.0.1,14330`; container API kết nối nội bộ tới `db:1433`. Login kỹ thuật `bluestock_app` dùng `APP_DB_PASSWORD` và quyền `db_owner` trên database demo để chạy API và bộ kiểm thử SQL. Đây không phải bốn role SQL dùng để chứng minh phân quyền theo rubric.

Với `sqlcmd` trong PATH, có thể chạy cổng đầy đủ bằng login kỹ thuật:

```powershell
$settings = ConvertFrom-StringData (Get-Content -LiteralPath .env -Raw)
$env:SQLCMDPASSWORD = $settings.APP_DB_PASSWORD
try {
    pwsh -File scripts/verify.ps1 -WithDatabase -WithConcurrency -SqlServer 'tcp:127.0.0.1,14330' -SqlUser bluestock_app
} finally {
    Remove-Item Env:SQLCMDPASSWORD -ErrorAction SilentlyContinue
}
```

Chạy kịch bản HTTP trong [`../testing/API_SMOKE.md`](../testing/API_SMOKE.md) để chứng minh nhập → tồn → xuất FEFO → báo cáo qua API thật. Muốn kiểm tra quyền SQL trực tiếp, dùng các script và ma trận trong [`../../database/security/README.md`](../../database/security/README.md).

## Vận hành và khắc phục

```powershell
docker compose logs db-init api
docker compose down
```

`down` giữ volume và dữ liệu demo. **Chỉ khi chủ động xóa database demo**, dùng `docker compose down -v` rồi khởi động lại. Không dùng volume này cho dữ liệu thật.

Nếu cổng máy chủ trùng ứng dụng khác, sửa `DB_PORT`, `API_PORT`, `WEB_PORT` trong `.env`. Với `API_PORT` khác 8080, mở frontend bằng `http://127.0.0.1:<WEB_PORT>/?mode=api&apiPort=<API_PORT>#products`; Compose tự cấu hình CORS theo `WEB_PORT`. Nếu `db-init` thất bại, xem log của nó trước khi thử khởi động API. Trên volume cũ có schema đầy đủ, `db-init` tự áp dụng migration 027 và 028; một database thiếu schema nền tảng sẽ bị từ chối và không bị xóa dữ liệu.
