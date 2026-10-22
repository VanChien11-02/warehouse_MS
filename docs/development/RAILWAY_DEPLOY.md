# Deploy SQL Server và Spring Boot lên Railway

Hướng dẫn cho backlog `REL-01`: frontend đã ở Vercel, SQL Server 2022 và API Java 21 chạy thành hai service trong cùng project/environment Railway. Đây là cấu hình demo đồ án; SQL Server Developer chỉ dùng cho phát triển, kiểm thử và demo. Hướng dẫn chưa phải bằng chứng đã deploy thành công trên tài khoản Railway.

```text
Trình duyệt -> Vercel /api/* -> Railway API -> Railway SQL Server
                                           (mạng riêng)
```

## 1. Chuẩn bị

- Push source lên GitHub để Railway build backend.
- Ghi lại domain production Vercel, ví dụ `https://bluestock-example.vercel.app`.
- Kiểm tra giới hạn RAM, storage, credit và Billing của Railway. SQL Server trên Linux cần ít nhất 2 GB RAM để khởi động; nên dành khoảng 3-4 GB giới hạn RAM cho service database khi demo, theo dõi Metrics và điều chỉnh theo tải. API cần RAM riêng. Gói chỉ cho 512 MB hoặc 1 GB mỗi service không đủ cho database này.
- Tạo ba mật khẩu khác nhau: mật khẩu `sa`, mật khẩu SQL login `bluestock_app` và mật khẩu admin ứng dụng. Mật khẩu SQL phải đủ độ phức tạp; dùng ít nhất 16 ký tự. Riêng mật khẩu `bluestock_app` dùng 12-64 ký tự chữ, số hoặc `@#%+=._!-` theo script của repo. Mật khẩu admin ít nhất 12 ký tự.
- Máy hiện có ODBC `sqlcmd`; dùng PowerShell 7 (`pwsh`) cho lệnh bên dưới.

Các giá trị có `<...>` và domain `example` là placeholder, phải thay trước khi dùng. Không gửi mật khẩu vào chat hoặc commit vào Git.

## 2. Tạo service SQL Server

1. Railway: tạo **Empty Project**, chọn environment dùng để demo.
2. Chọn **New -> Docker Image**, nhập `mcr.microsoft.com/mssql/server:2022-latest`, đặt tên service là `db`.
3. Trong **Variables**, đặt:

   | Biến | Giá trị |
   | --- | --- |
   | `ACCEPT_EULA` | `Y` |
   | `MSSQL_PID` | `Developer` |
   | `MSSQL_SA_PASSWORD` | Mật khẩu `sa` vừa tạo |
   | `MSSQL_TCP_PORT` | `1433` |
   | `RAILWAY_RUN_UID` | `0` |

4. Gắn **Volume** vào service `db`, mount path `/var/opt/mssql`. Railway mount volume với quyền root; `RAILWAY_RUN_UID=0` xử lý quyền ghi của image SQL Server trong cấu hình demo này. Dữ liệu nằm trên volume sẽ được giữ qua redeploy; không xóa volume khi muốn giữ database.
5. Đặt giới hạn tài nguyên đủ RAM như bước chuẩn bị. Chọn cùng region cho DB và API. Để trống HTTP healthcheck của DB vì SQL Server dùng TCP.
6. Deploy, xem logs đến khi có thông báo SQL Server sẵn sàng nhận kết nối. Chỉ trạng thái container `Active` chưa chứng minh database sẵn sàng.
7. Trong **Settings -> Networking**, ghi lại private domain thực tế, thường là `db.railway.internal`. Project/environment mới hỗ trợ private IPv4 và IPv6; environment cũ chỉ có IPv6 có thể cần cấu hình mạng bổ sung.
8. Tạo **TCP Proxy** với target port `1433` để máy bạn khởi tạo schema. Railway cấp public host và public port riêng; ghi lại cả hai. Không dùng Generate Domain HTTPS cho SQL Server.

## 3. Tạo database, schema và dữ liệu demo

Image SQL Server không tự chạy `database/init.sql` của repo. Backend đang dùng `ddl-auto: none`, nên phải khởi tạo trước khi deploy API.

Mở PowerShell 7 tại root repository. Thay host/port bên dưới bằng TCP Proxy Railway; dấu phân cách SQL Server là dấu phẩy. Mật khẩu được nhập ẩn, không đặt trong câu lệnh lịch sử:

```powershell
Set-Location E:\HQTCSDL\project
$railwaySqlServer = 'tcp:<PUBLIC_HOST>,<PUBLIC_PORT>'
$env:SQLCMDPASSWORD = Read-Host 'Nhap mat khau sa' -MaskInput
$env:APP_DB_PASSWORD = Read-Host 'Nhap mat khau bluestock_app' -MaskInput
try {
    if ($env:APP_DB_PASSWORD -cnotmatch '^[A-Za-z0-9@#%+=._!-]{12,64}$') {
        throw 'Mat khau app khong dung dinh dang da quy dinh.'
    }
    sqlcmd -S $railwaySqlServer -U sa -C -b -Q 'SELECT @@VERSION;'
    if ($LASTEXITCODE -ne 0) { throw 'Khong ket noi duoc SQL Server.' }

    sqlcmd -S $railwaySqlServer -U sa -C -b -f i:65001 -i database/init.sql
    if ($LASTEXITCODE -ne 0) { throw 'Khoi tao schema that bai; dung va xem loi.' }

    sqlcmd -S $railwaySqlServer -U sa -C -b -f i:65001 -d BlueStock -i database/seed/demo.sql
    if ($LASTEXITCODE -ne 0) { throw 'Seed demo that bai.' }

    sqlcmd -S $railwaySqlServer -U sa -C -b -f i:65001 -i database/docker-app-login.sql
    if ($LASTEXITCODE -ne 0) { throw 'Tao SQL login app that bai.' }
} finally {
    Remove-Item Env:SQLCMDPASSWORD, Env:APP_DB_PASSWORD -ErrorAction SilentlyContinue
}
```

`sqlcmd` đọc `APP_DB_PASSWORD` từ biến môi trường để thay macro trong script login. Chạy từ root là bắt buộc vì `init.sql` và seed dùng các đường dẫn `:r` tương đối. `-C` tin cậy chứng chỉ tự ký của SQL Server trong môi trường demo.

Chỉ chạy `init.sql` khi database `BlueStock` chưa tồn tại. Nếu khởi tạo lỗi giữa chừng, xem lỗi và trạng thái schema trước khi xử lý; không chạy lại bằng cách xóa database đang có dữ liệu. Script seed và login không tạo tài khoản đăng nhập web. Login `bluestock_app` được cấp `db_owner` theo cấu hình demo hiện có; cần giảm quyền theo thiết kế riêng nếu dùng dữ liệu thật.

## 4. Deploy API

1. Trong cùng project/environment, chọn **New -> GitHub Repo**, chọn repository và branch chứa code.
2. Đặt service name `api`, **Root Directory** là `/services/api`. Railway sẽ dùng `Dockerfile` trong thư mục này. Giữ Build Command và Start Command mặc định của Dockerfile; không điền lệnh chạy Maven thủ công.
3. Đặt các biến sau trước khi deploy, thay private domain nếu khác `db.railway.internal`:

   | Biến | Giá trị |
   | --- | --- |
   | `PORT` | `8080` |
   | `SERVER_PORT` | `8080` |
   | `SPRING_DATASOURCE_URL` | `jdbc:sqlserver://db.railway.internal:1433;databaseName=BlueStock;encrypt=true;trustServerCertificate=true` |
   | `SPRING_DATASOURCE_USERNAME` | `bluestock_app` |
   | `SPRING_DATASOURCE_PASSWORD` | Mật khẩu app đã nhập ở bước 3 |
   | `APP_WEB_ORIGIN` | Domain production Vercel, gồm `https://`, không có dấu `/` cuối |
   | `SERVER_FORWARD_HEADERS_STRATEGY` | `framework` |
   | `SERVER_SERVLET_SESSION_COOKIE_SECURE` | `true` |
   | `SERVER_SERVLET_SESSION_COOKIE_SAME_SITE` | `lax` |
   | `APP_BOOTSTRAP_ADMIN_ENABLED` | `true` |
   | `APP_BOOTSTRAP_ADMIN_IF_EMPTY` | `true` |
   | `APP_BOOTSTRAP_ADMIN_USERNAME` | `admin` |
   | `APP_BOOTSTRAP_ADMIN_PASSWORD` | Mật khẩu admin ứng dụng |

4. Đặt **Healthcheck Path** `/actuator/health`. Endpoint này kiểm tra cả kết nối DB; `/api/health` chỉ kiểm tra tiến trình. Đảm bảo `PORT`, `SERVER_PORT` và target port public đều là `8080`.
5. Deploy. Nếu deployment đầu tự chạy trước khi đặt biến hoặc trước khi DB sẵn sàng, cấu hình xong rồi redeploy.
6. Vào **Networking -> Generate Domain**, target port `8080`. Ghi lại URL HTTPS của API.
7. Mở `https://<API_DOMAIN>/actuator/health`, kết quả cần có `"status":"UP"`.

Bootstrap tạo admin chỉ khi bảng tài khoản trống. Với database demo mới ở bước 3, dùng username `admin` và mật khẩu bootstrap để đăng nhập web. Khi đã tạo thành công, đặt `APP_BOOTSTRAP_ADMIN_ENABLED=false`, bỏ `APP_BOOTSTRAP_ADMIN_PASSWORD` và redeploy. Đổi biến bootstrap sau này không đổi mật khẩu tài khoản đã tồn tại.

## 5. Nối frontend Vercel với API

Frontend hiện gọi API ở `127.0.0.1`. Chỉ thêm biến môi trường Vercel không đổi được URL này vì frontend là JavaScript tĩnh, chưa có bước build đọc biến môi trường.

Trong `apps/web/app.js`, thay dòng khai báo `API_BASE_URL` bằng cấu hình giữ localhost khi chạy local và dùng proxy cùng origin khi deploy:

```javascript
const API_BASE_URL = ["127.0.0.1", "localhost"].includes(window.location.hostname)
  ? `http://127.0.0.1:${apiPort}/api`
  : "/api";
```

Nếu Vercel Root Directory đang là `apps/web`, tạo `apps/web/vercel.json` với nội dung sau, thay domain API thật:

```json
{
  "rewrites": [
    {
      "source": "/api/:path*",
      "destination": "https://<API_DOMAIN>/api/:path*"
    }
  ]
}
```

Nếu đã có `vercel.json`, thêm rule vào cấu hình hiện có và đặt trước rule bắt tất cả route; không ghi đè các rule khác. File cấu hình phải nằm trong Root Directory mà Vercel đang dùng.

Push thay đổi và redeploy Vercel. Proxy giữ request trình duyệt ở domain Vercel, phù hợp session cookie `SameSite=Lax` mà không phụ thuộc cookie bên thứ ba. Không đặt domain cookie thành domain Railway. `APP_WEB_ORIGIN` phải khớp domain Vercel bạn đang truy cập; URL preview khác domain cần cấu hình riêng.

Hướng dẫn này chỉ chứa mẫu thay đổi frontend; chưa tự sửa `app.js` hoặc tạo `vercel.json` vì chưa có domain API thật.

## 6. Kiểm tra sau triển khai

1. Kiểm tra API trực tiếp: `https://<API_DOMAIN>/actuator/health` trả `UP`.
2. Kiểm tra proxy: `https://<VERCEL_DOMAIN>/api/health` trả JSON, không phải trang HTML.
3. Mở `https://<VERCEL_DOMAIN>/?mode=api#accounts`, đăng nhập admin.
4. Trong DevTools Network, xác nhận request đi tới domain Vercel `/api/...`, không còn `127.0.0.1`. Kiểm tra `/api/auth/me` sau login và một thao tác ghi để xác nhận session/CSRF.
5. Thử tạo nhân viên và tài khoản, đăng xuất/đăng nhập lại, redeploy API và xác nhận dữ liệu vẫn còn. Session nằm trong bộ nhớ nên sau khi API restart cần đăng nhập lại.
6. Dùng admin cấp role `QLKHO` cho tài khoản thử nghiệp vụ kho. Admin không tự có quyền lập hoặc hoàn tất nhập/xuất. Đăng nhập tài khoản `QLKHO` rồi chạy luồng nhập -> tồn -> xuất FEFO -> báo cáo theo [API smoke](../testing/API_SMOKE.md).
7. Khi không cần truy cập SQL trực tiếp từ máy nữa, xóa TCP Proxy public của DB. API vẫn dùng private domain. Giữ volume và thiết lập backup nếu cần giữ dữ liệu demo.

Trước bàn giao, chạy cổng repo:

```powershell
pwsh -File scripts/verify.ps1
```

Muốn chạy thêm SQL/concurrency từ máy bạn, giữ TCP Proxy tạm thời, đặt `SQLCMDPASSWORD` bằng mật khẩu `bluestock_app`, rồi chạy:

```powershell
pwsh -File scripts/verify.ps1 -WithDatabase -WithConcurrency -SqlServer 'tcp:<PUBLIC_HOST>,<PUBLIC_PORT>' -SqlUser bluestock_app
```

Chạy trên database demo, và xóa biến môi trường mật khẩu sau khi kiểm tra. Chế độ demo dùng dữ liệu mẫu; các màn hình được cấp quyền trong chế độ API dùng backend theo [README frontend](../../apps/web/README.md).

## Lỗi thường gặp

| Triệu chứng | Kiểm tra |
| --- | --- |
| SQL Server thoát ngay / OOM | Giới hạn RAM, credit, `ACCEPT_EULA`, độ phức tạp mật khẩu và Deploy Logs |
| Permission denied trong `/var/opt/mssql` | Mount path và `RAILWAY_RUN_UID=0` |
| Không kết nối được từ `sqlcmd` | TCP Proxy trỏ `1433`, public host/port đúng, SQL đã ready |
| API báo login failed | Login `bluestock_app` đã tạo và mật khẩu trùng bước 3 |
| Invalid object name / không thấy bảng | `init.sql` chưa thành công, sai `databaseName` hoặc JDBC trỏ nhầm DB |
| Railway healthcheck timeout / HTTP 502 | API đã listen `8080`, `PORT=8080`, target port đúng, DB private domain đúng |
| Frontend vẫn gọi localhost | Chưa đổi `API_BASE_URL` hoặc Vercel chưa deploy commit mới |
| `/api/health` trả HTML | `vercel.json` sai Root Directory hoặc rule catch-all đứng trước proxy |
| Login rồi vẫn 401 / ghi bị 403 | Cookie session, CSRF token, origin chính xác và frontend gọi cùng origin qua proxy |
| Không hoàn tất được chứng từ | Tài khoản chưa có role `QLKHO` hoặc lỗi nghiệp vụ từ API |

## Tài liệu nền tảng

- [Railway: Dockerfile](https://docs.railway.com/builds/dockerfiles)
- [Railway: Volume và quyền truy cập](https://docs.railway.com/volumes)
- [Railway: Private networking](https://docs.railway.com/networking/private-networking)
- [Railway: Private domain IPv4/IPv6](https://docs.railway.com/networking/domains/working-with-domains)
- [Railway: TCP Proxy](https://docs.railway.com/networking/tcp-proxy)
- [Railway: Healthcheck và PORT](https://docs.railway.com/deployments/healthchecks)
- [Microsoft: Yêu cầu SQL Server Linux](https://learn.microsoft.com/sql/linux/install-upgrade/setup?view=sql-server-ver16)
- [Microsoft: Biến môi trường SQL Server](https://learn.microsoft.com/en-us/sql/linux/configure/environment-variables?view=sql-server-ver16)
- [Vercel: External rewrites](https://vercel.com/docs/routing/rewrites)
