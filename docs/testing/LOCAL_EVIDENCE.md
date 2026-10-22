# Kết quả kiểm chứng local

## Đồng bộ màn hình demo/API (2026-10-22)

Phạm vi: SEC-01, CAT-01, LOC-01, FE-02, TRF-01, CNT-01, RET-01, REP-01,
AUD-01. Backend bổ sung `GET /api/quyen-han` chỉ dành cho Admin; frontend dùng
API cho bảy danh mục, mapping đối tác, năm chứng từ nhiều dòng, tổng quan,
ma trận quyền, hạn dùng, chênh lệch kiểm kê và audit. Không thay schema.

| Lệnh/kiểm tra | Kết quả |
| --- | --- |
| `pwsh -File scripts/verify.ps1` | Exit 0: 15 test frontend, 162 test Java; kiểm tra cú pháp và liên kết Markdown đạt. Host dùng JDK 24, compile target Java 21. Lần đầu trong sandbox lỗi truy cập Maven/cache; chạy lại với quyền môi trường host đạt. |
| `node scripts/verify-web-parity.mjs` với `PLAYWRIGHT_PATH` trỏ thư viện bundled, `PLAYWRIGHT_CHANNEL=msedge`, `WEB_TEST_URL=http://127.0.0.1:5177` | Exit 0: bốn role, bảy màn danh mục, tạo kho, năm luồng lưu/hoàn tất chứng từ, quyền chỉ đọc/không được hoàn tất, desktop 1440px và mobile 390px; 124 request API giả lập, không lỗi JavaScript hoặc tràn viewport. |
| `impeccable.cmd detect --json` trên các file UI sửa | Exit 0, kết quả `[]`. Đã xem ảnh desktop/mobile của ma trận quyền và phiếu chuyển. |
| `docker compose build api web` | Exit 0, API build bằng Java 21. |
| `docker compose up -d --no-deps api web` | Exit 0; thay hai container ứng dụng bằng image mới, giữ SQL Server và volume. |
| Playwright với web 5174 và API 8080 thật | Đăng nhập Admin bằng cấu hình local trong bộ nhớ, đọc bốn vai trò/chín nhóm quyền và 12 danh sách danh mục/chứng từ trên SQL Server, đăng xuất; không lỗi JavaScript. Không ghi mật khẩu/cookie/token vào artifact. |

Ảnh và output trình duyệt nằm trong thư mục artifact của phiên làm việc,
không đưa vào Git. Script trình duyệt giả lập có thể chạy lại bằng cách cài
Playwright ngoài frontend rồi đặt `PLAYWRIGHT_PATH`; tùy chọn `WEB_TEST_OUTPUT`
chỉ nơi lưu ảnh. Chạy web qua `scripts/dev.ps1` trước khi dùng script này.

Giới hạn: lượt này không chạy lại bộ SQL/concurrency và không ghi sổ nhập/xuất
trên database đang demo. Browser test giả lập kiểm tra điều hướng/payload/UI;
không thay thế kiểm tra transaction trên SQL Server. Kiểm kê lưu từng dòng qua
API riêng; nếu một dòng lỗi thì những dòng đã lưu vẫn là nháp và có thể tiếp tục.
Tập vai trò cố định, không có API tạo vai trò hoặc sửa policy tùy ý.

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

## Bốn trigger bảo vệ kho mới (2026-10-21)

Môi trường: SQL Server 2022 trong Docker Compose ở `tcp:127.0.0.1,14330`; `sqlcmd` đăng nhập bằng `bluestock_app` với `SQLCMDPASSWORD` lấy từ `.env` local, không ghi vào log/repository. Bộ Maven trên host dùng JDK 24, biên dịch target Java 21. Các lệnh dưới đây chạy từ root repository.

| Lệnh/kiểm tra | Kết quả |
| --- | --- |
| `sqlcmd ... -d BlueStock -i database/migrations/027_inventory_guard_triggers.sql` | Exit 0; cài bốn trigger mới trên volume demo trước đó chỉ có một trigger |
| `sqlcmd ... -d BlueStock -i database/tests/024_inventory_guard_triggers.sql` | Exit 0, `Inventory guard triggers passed.`; test thêm/sửa nhiều dòng sai, rollback toàn câu và đường ghi hợp lệ |
| `pwsh -File scripts/verify.ps1 -WithDatabase -WithConcurrency -SqlServer 'tcp:127.0.0.1,14330' -SqlUser bluestock_app` | Exit 0: 8 test frontend, 157 test Java, 24 script SQL và hai session xuất cạnh tranh đạt; `Baseline verification passed.` |
| Bản sao `database/init.sql` chỉ thay tên database sang `BlueStockTrig30c2a61c`, chạy bằng `sqlcmd -U sa`, rồi chạy test 024 | Exit 0; database sạch trên SQL Server 2022 có đúng 5 trigger enabled; database và file script tạm đã xóa sau kiểm tra |
| `docker compose up -d --no-build --force-recreate db-init` trên volume cũ | `db-init` exit 0; chạy lại migration 027/seed thành công, vẫn có 5 trigger enabled và 3 lô mẫu `PND001` |
| `docker compose up -d --no-build api web`, `GET /actuator/health`, `GET /?mode=api#products` | API trả `UP`, web HTTP 200; chưa chạy lại kịch bản HTTP nhập → xuất đầy đủ trong lượt này |

Trong lần chạy test 024 đầu tiên, tên đơn vị tính fixture trùng dữ liệu seed và bị unique constraint từ chối. Đã đổi fixture sang tên riêng `TST241`/`TST242`, chạy lại test 024 và cổng đầy đủ đều đạt.

## Phân vai API và đối soát Kế toán (2026-10-22)

Môi trường: Docker Compose SQL Server 2022, API chạy Java 21 trong container;
host chạy Maven bằng JDK 24. Migration 028 được áp dụng lên volume demo hiện có.

| Lệnh/kiểm tra | Kết quả |
| --- | --- |
| `docker compose run --rm db-init` | Exit 0; migration 028 thêm bảng đối soát, đồng bộ quyền SQL và seed lặp lại được |
| `pwsh -File scripts/verify.ps1 -WithDatabase -SqlServer '127.0.0.1,14330' -SqlUser sa` với `SQLCMDPASSWORD` đọc từ `.env` local | Exit 0; 15 test frontend, 170 test Java và 25 script SQL đạt; `Baseline verification passed.` |
| `impeccable.cmd detect --json apps/web/features/live-insights.js apps/web/features/live-documents.js apps/web/styles.css` | Exit 0, không phát hiện vấn đề (`[]`) |
| `git diff --check` | Exit 0; chỉ có cảnh báo Git về chuyển LF/CRLF khi chạm file |
| `docker compose up -d --build api web` | Exit 0; image API/web mới được dựng và hai container khởi động |
| `GET http://127.0.0.1:8080/actuator/health`, `GET http://127.0.0.1:5174/?mode=api#dashboard` | API trả `UP`, web trả HTTP 200; màn đăng nhập API hiển thị trong browser |

Chưa kiểm tra bằng thao tác trình duyệt sau khi đăng nhập đủ bốn vai trò trong lượt này; quyền HTTP được bao phủ bởi controller test, còn role SQL, schema và nghiệp vụ đối soát được kiểm tra bằng test tương ứng.

Sau khi thêm biểu đồ khối lượng phiếu vào dashboard API, cùng lệnh `verify.ps1 -WithDatabase` được chạy lại và vẫn exit 0 với 15 test frontend, 170 test Java, 25 script SQL. Lệnh `docker compose up -d --build web` để đưa riêng biểu đồ mới lên container bị từ chối ở bước cấp quyền, nên container web đang chạy là bản trước thay đổi biểu đồ cuối này; mã nguồn và toàn bộ kiểm tra đã cập nhật.
