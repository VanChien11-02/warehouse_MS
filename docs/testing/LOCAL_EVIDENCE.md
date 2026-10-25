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

## Phương án thực hành trigger đã thay thế (2026-10-25)

Lượt trước từng kiểm tra UI thực hành tách biệt: 183 test Java, 16 test
frontend, bốn ca SQL và browser desktop/mobile đạt. Project Owner sau đó
bác bỏ phương án vì không thuộc quy trình vận hành kho. UI, endpoint,
fixture SQL và test riêng của phương án này đã được gỡ; kết quả lịch sử
không dùng làm bằng chứng cho luồng nghiệp vụ hiện tại. Ranh giới mới nằm
trong [ADR 0008](../architecture/adr/0008-inbound-integrity-boundary.md).

## Trigger trong luồng nhập thật (2026-10-25)

Theo quyết định mới nhất, đã gỡ toàn bộ UI/API/SQL fixture thực hành, tách
quy tắc thiếu lượng (procedure) và vượt lượng (trigger). Migration 029 nâng
cấp procedure hiện có; không đổi schema, không cho sửa phiếu hoàn tất. API
hiển thị thông báo nghiệp vụ có cách khắc phục, không đưa tên object SQL lên UI.

| Lệnh/kiểm tra | Kết quả |
| --- | --- |
| `sqlcmd -S localhost -E -C -b -f i:65001 -d BlueStock -i database/migrations/029_inbound_trigger_boundary.sql`, sau đó test 009 và 024 | Exit 0; gọi procedure nhập thật với 10 so với 6+5 nhận đúng ERROR_NUMBER 51820, ERROR_PROCEDURE `trg_LoHang_GioiHanPhanBo`. Kiểm tra rollback cả lô/tồn/sổ/audit COMPLETE, phiếu còn NHAP; test cả hai chiều trigger nhiều dòng đạt. |
| `pwsh -File scripts/verify.ps1 -WithDatabase` | Exit 0; 16 test frontend, 177 test Java (không lỗi/bỏ qua) và 25 bài SQL đạt; cú pháp/liên kết Markdown đạt. Host JDK 24, target Java 21, SQL Server local. |
| `docker compose up -d --build` | Exit 0; API Java 21/web mới chạy cùng SQL Server 2022; db-init áp migration 029 lên volume đang có. |
| `node scripts/verify-inbound-rollback-ui.mjs` với tài khoản/danh mục/vị trí test riêng | Exit 0; form nhập thật, login/API/SQL Server thật: 6+5 → 422 ALLOCATION_EXCEEDS_LINE; 6+3 → 422 ALLOCATION_INCOMPLETE; vị trí Hư hỏng → 422 INCOMPATIBLE_STORAGE; 6+4 hoàn tất, hai lô 6 và 4, tồn tăng đúng 10. Các ca lỗi giữ nháp và tồn cũ; hoàn tất lại → 409, tồn không tăng thêm. Desktop 1440 và mobile 390 không tràn ngang/pageerror; không còn mục thực hành. |
| Cập nhật riêng web bằng `docker compose up -d --build --no-deps web`, chạy lại browser gate | Exit 0; các ca nhập, rollback và chống lặp vẫn đạt. Sau khi xem ảnh, sửa thêm độ ưu tiên CSS để thông báo trong editor nền sáng dùng đỏ đậm thay vì utility màu nhạt của nền tối. |
| `git diff --check`, `node --check scripts/verify-inbound-rollback-ui.mjs` | Exit 0; Git chỉ cảnh báo LF/CRLF. |

Ảnh desktop/mobile trong artifact phiên làm việc. Browser test tạo các phiếu
PN0052–PN0055 trên dữ liệu riêng; sau mỗi lượt đã dọn đúng chứng từ, lô, tồn,
sổ, danh mục, vị trí, tài khoản và audit của fixture, không đụng phiếu người
dùng. Secret chỉ đọc vào bộ nhớ; không lưu mật khẩu/cookie/token vào Git/ảnh.

Kiểm tra cơ học Impeccable khi bao gồm cả `index.html` báo các cảnh báo giao
diện có sẵn trên toàn app (màu/độ tương phản/chữ nhỏ và advisory thiết kế).
Phạm vi này sửa độ tương phản thông báo lỗi trong editor chứng từ; chưa audit
hoặc sửa toàn bộ giao diện cũ. Browser đã xác nhận hai kích thước, thông báo
đọc được và không có lỗi JavaScript.

Giới hạn nghiệp vụ: trigger chiều giảm dòng không có đường phát lỗi từ UI
hiện tại vì chỉ tạo lô khi hoàn tất và không sửa phiếu hoàn tất. Nó được kiểm
chứng ở cấp bảng bằng test 024, không mô tả lỗi procedure hay khóa form thành
lỗi trigger. Chưa triển khai bản mới lên hosting từ xa.

## Thay trigger dòng nhập bằng guard bảo quản loại sản phẩm (2026-10-25)

Theo yêu cầu tiếp theo của Project Owner, gỡ `trg_CtPhieuNhap_GioiHanLo`, thêm
`trg_LoaiSanPham_BaoVeBaoQuan`. Loại đã có lô không đổi yêu cầu bảo quản; loại
chưa có lô đổi được, tên/mô tả vẫn sửa được. Chi tiết và giới hạn đường ghi
trực tiếp CT_PHIEU_NHAP tại [ADR 0009](../architecture/adr/0009-category-storage-history-guard.md).

| Lệnh/kiểm tra | Kết quả |
| --- | --- |
| Migration 030, test 024 và test 009 qua `sqlcmd -S localhost -E -C -b -f i:65001 -d BlueStock -i ...` | Exit 0; trigger cũ không còn, trigger mới nhận đúng 51825/ERROR_PROCEDURE; UPDATE nhiều loại rollback cả câu, NULL bị chặn; giữ bảo quản/sửa tên và loại chưa có lô được phép. Nhập/vượt lượng/rollback vẫn đạt. |
| `pwsh -File scripts/verify.ps1 -WithDatabase` | Exit 0; 181 test Java, 16 test frontend, 25 bài SQL; không lỗi hoặc bỏ qua. Host JDK 24, target Java 21; SQL Server local. |
| `docker compose up -d --build`, sau đó `docker compose up -d` | API/web mới dựng thành công. Lần khởi động đầu db-init gặp database chưa mở xong dù master healthcheck đã đạt; chạy lại sau recovery thành công, giữ nguyên volume. Migration 027/029/030 áp theo thứ tự, trigger cũ bị gỡ. API chạy Java 21, SQL Server 2022. |
| `node scripts/verify-category-storage-ui.mjs` qua runner cấu hình fixture riêng | Exit 0; đăng nhập QLKHO thật, sửa loại trên form thật: Khô → Mát và NULL nhận 409 CATEGORY_STORAGE_LOCKED, DB giữ Khô; giữ Khô sửa tên/mô tả thành công; loại chưa có lô đổi được. Desktop 1440/mobile 390, không tràn ngang/pageerror. |
| Bản sao `init.sql` đổi tên sang database tạm `BlueStockGuardCheck69bbf28c`, test 024, chạy lại migration 030 | Exit 0; schema sạch không có trigger cũ, bộ guard đạt, migration chạy lại được. Database/file SQL tạm đã dọn. |
| `impeccable.cmd detect --json apps/web/styles.css` | Exit 0, `[]`; đã xem ảnh dialog desktop/mobile. |

Browser runner nhận `CATEGORY_TEST_USERNAME`, `CATEGORY_TEST_PASSWORD`,
`CATEGORY_TEST_USED` (có lô, bảo quản Khô), `CATEGORY_TEST_UNUSED` (chưa có lô)
và các biến Playwright/URL/ảnh như gate khác. Lượt này tạo dữ liệu riêng qua
API, hoàn tất nhập để có lô thật; đã dọn đúng danh mục, kho/vị trí, chứng từ,
lô/tồn/sổ, tài khoản và audit fixture. Không lưu secret trong source/ảnh.

Giới hạn: chưa chạy riêng bài hai session nhập và sửa yêu cầu bảo quản đồng
thời; procedure đã giữ HOLDLOCK loại đến cuối transaction. Các ca tuần tự,
rollback, role, database sạch/volume cũ và UI thật đã kiểm chứng. Bản mới chỉ
cập nhật local, chưa deploy hosting từ xa.

## Rút gọn thủ tục nhập để trình bày (2026-10-25)

Thủ tục nhập chia năm bước có chú thích tiếng Việt, gộp kiểm tra đơn vị của
hàng mới/tồn cũ và chuyển đổi ngày một lần. Giữ nguyên contract, khóa phiếu,
loại/vị trí, vòng lặp tạo từng lô, mã lỗi và ghi sổ nguyên tử. Migration 031
đồng bộ canonical; Compose áp 031 sau 030. Hướng dẫn đọc code và lời trình
bày tại [`../development/INBOUND_WALKTHROUGH.md`](../development/INBOUND_WALKTHROUGH.md).

| Lệnh/kiểm tra | Kết quả |
| --- | --- |
| `sqlcmd -S localhost -E -C -b -f i:65001 -d BlueStock -i database/migrations/031_simplify_inbound_completion.sql`, rồi test 009 | Exit 0; ngày hợp lệ giữ đúng, ngày sai/hạn trước NSX nhận 51104; trộn đơn vị giữa hai hàng mới và giữa hàng mới/tồn cũ nhận 51111; commit, chống lặp, thiếu lượng, sức chứa, mapping và lỗi trigger 51820 rollback đạt. |
| `pwsh -File scripts/verify.ps1 -WithDatabase` với JAVA_HOME JDK 24 | Exit 0; 181 test Java, 16 test frontend, 25 script SQL đạt; cú pháp/liên kết Markdown đạt. |
| Pipe nội dung migration 031 rồi test 009 vào `docker compose exec -T db /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -b -f i:65001 -d BlueStock` | Exit 0; database SQL Server 2022 mà API/UI local đang dùng đã cập nhật, không cần dựng lại API/web. |
| `node scripts/verify-inbound-rollback-ui.mjs` qua runner dữ liệu riêng | Exit 0; desktop/mobile: 6+5 nhận lỗi và giữ tồn, 6+3 bị chặn, vị trí hư hỏng bị chặn, sửa 6+4 hoàn tất với hai lô, tồn tăng 10, gọi lại 409 không tăng tồn; không overflow/pageerror. PN0103/PN0104 và toàn bộ fixture riêng đã dọn. |
| `git diff --check` | Exit 0; chỉ cảnh báo LF/CRLF. |

Lượt refactor này không chạy lại bài concurrency hai session hoặc dựng
database sạch; không đổi schema hay thứ tự khóa. Chưa deploy hosting từ xa.

## API và UI lịch sử nhập kho từ view (2026-10-25)

`GET /api/phieu-nhap/lich-su` → InboundService →
InboundJdbcRepository.findHistory đọc trực tiếp `dbo.vw_LichSuNhapKho`.
Không đổi schema hoặc view, không thêm migration. Tab Lịch sử nhập kho trong
màn Phiếu nhập hiển thị từng lô, bộ lọc mã/ngày UTC, phân trang và link mở
chứng từ gốc. QLKHO/KETOAN được đọc, NVKHO/ADMIN bị chặn; ma trận quyền đã
cập nhật. Contract tại [`../../contracts/inbound-completion.md`](../../contracts/inbound-completion.md).

| Lệnh/kiểm tra | Kết quả |
| --- | --- |
| `mvn -q -Dtest=InboundControllerTest,InboundServiceTest test` (JAVA_HOME JDK 24) | Exit 0; route tĩnh lịch sử, QLKHO/KETOAN, từ chối NVKHO/ADMIN/anonymous, malformed date, chuẩn hóa mã, page/size/date validation đạt. Lần đầu trong sandbox không đọc/tải được Maven parent; chạy ngoài sandbox đạt. |
| `pwsh -File scripts/verify.ps1 -WithDatabase` | Exit 0; 187 test Java, 17 test frontend, 25 bài SQL; cú pháp/Markdown đạt. Test 009 xác nhận view không có phiếu nháp/rollback và phản ánh đúng lượng/giá trị sau commit. |
| `docker compose up -d --build api web` | Exit 0; API Java 21/web mới chạy trên SQL Server 2022, db-init áp migration hiện hành thành công. |
| `node scripts/verify-inbound-rollback-ui.mjs` qua runner fixture riêng, hai lượt | Exit 0 cả hai lượt, desktop1440/mobile390: draft và rollback không vào lịch sử; hoàn tất6+4 có hai lô, giá trị75000/50000; code/date filters và phân trang API size1 đạt; tab hiển thị đúng, lỗi503 chủ động/empty/retry, mở phiếu gốc và bàn phím chuyển tab đạt; không overflow/pageerror. PN0105–PN0108 và fixture riêng đã dọn. |
| `impeccable.cmd detect --json apps/web/styles.css apps/web/features/live-inbound-history.js` | Exit 0, `[]`. Review ảnh chỉ ra bảng mobile hẹp và nút ngắt dòng; sửa cùng một batch, dựng riêng web bằng `docker compose up -d --build --no-deps web`, chụp lại hai kích thước; reviewer chấm cả ba điểm đã sửa đạt trong phạm vi đó. |
| Kiểm tra cú pháp module/app, `node --test apps/web/data/document-api.test.mjs`, `git diff --check` sau sửa responsive | Exit 0; hai test adapter đạt; Git chỉ cảnh báo LF/CRLF. |

Ảnh `inbound-history-1440.png`/`inbound-history-390.png` lưu trong artifact
phiên làm việc. Browser dùng QLKHO thật và SQL Server thật, mock chỉ dùng
riêng ca lỗi503 có chủ đích; không lưu secret. UI phân trang được kiểm tra
trạng thái một trang; chuyển trang nhiều kết quả kiểm tra qua API size1.
Chưa chạy riêng browser KETOAN/NVKHO, concurrency hoặc database sạch trong
lượt này; phân quyền có controller test và quyền view SQL sẵn có được gate
SQL kiểm tra. Bản chạy cập nhật local, chưa deploy hosting từ xa.

## Bộ học SQL ngắn trên SSMS cho TV1 (2026-10-25)

Theo yêu cầu của Project Owner, đọc sáu bài giảng Index/View/Function/Trigger/
SP/Transaction P1 tại thư mục `E:\tai_lieu\hệ quản trị cơ sở dữ liệu\utexlms`;
trích xuất nội dung và xem ảnh các trang cú pháp. Mẫu được chuyển sang bảng
kho hiện hành, ghi nguồn/trang và lời giải thích tại
[`../development/TV1_HOC_SQL_SSMS.md`](../development/TV1_HOC_SQL_SSMS.md).
Không đổi object/UI production. Script thực thi trong project là
[`../../database/study/01_tv1_kiem_tra_ssms.sql`](../../database/study/01_tv1_kiem_tra_ssms.sql),
chỉ đọc metadata/dữ liệu, bài transaction dùng bảng tạm.

| Lệnh/kiểm tra | Kết quả |
| --- | --- |
| Bản init đổi tên thành database tạm `BlueStockStudyCheck01a17217`, gỡ object tương ứng ở database tạm, chạy tám block từ hướng dẫn | Exit 0; CREATE index/view/function/hai trigger/proc mẫu, CHECK/FK và transaction bảng tạm chạy được. Kết quả rollback10, commit6. |
| `sqlcmd -S localhost -E -C -b -f i:65001 -d BlueStockStudyCheck01a17217 -i database/tests/009_inbound_completion.sql`, rồi test024 | Exit 0 cả hai; mẫu view/hàm/trigger rút gọn giữ hành vi kiểm tra nhập, rollback và nhiều dòng. Database tạm đã DROP sau kiểm tra. |
| `sqlcmd -S localhost -E -C -b -f i:65001 -i database/study/01_tv1_kiem_tra_ssms.sql` | Exit 0; metadata index/cột INCLUDE, định nghĩa object/constraint, SELECT view/hàm và hai ca bảng tạm đạt trên SQL Server Windows local. Không tuyên bố hiệu năng tăng dựa trên lượt này; SSMS Actual Execution Plan chưa được thao tác riêng. |
| `pwsh -File scripts/verify.ps1` với JAVA_HOME JDK24 | Exit 0; 187 test Java, 17 frontend, cú pháp/Markdown đạt. Không chạy lại toàn bộ 25 bài SQL ở lượt tài liệu này, chỉ chạy hai bài liên quan trên database tạm. |

Mẫu EXEC hoàn tất trong tài liệu yêu cầu người học tự tạo một phiếu nháp
10 qua UI và thay mã phiếu/vị trí; không tự chọn và ghi sổ phiếu thật của
người dùng để kiểm tra. Không chạy UI/browser lại vì không thay frontend/API.

Điều chỉnh tiếp theo theo yêu cầu người học: file
`database/study/01_tv1_kiem_tra_ssms.sql` chuyển sang **chỉ SELECT**, bỏ các
lệnh EXEC và bài bảng tạm khỏi file kiểm tra. SELECT các catalog sys.indexes,
sys.views, sys.objects, sys.triggers, sys.procedures, sys.check_constraints,
sys.foreign_keys và OBJECT_DEFINITION. Chọn BlueStock trong dropdown SSMS.
Chạy `sqlcmd -S localhost -E -C -b -f i:65001 -d BlueStock -i database/study/01_tv1_kiem_tra_ssms.sql`
đạt exit0, trả đúng tên object/điều kiện FK-CHECK; hai trigger và index đang bật.

## Minh chứng hành vi SQL trên SSMS (2026-10-25)

Theo giải thích tiếp theo của người học, bổ sung kịch bản thực thi nghiệp vụ:
[`../../database/study/00_tv1_chuan_bi_demo.sql`](../../database/study/00_tv1_chuan_bi_demo.sql),
[`../../database/study/02_tv1_demo_hanh_vi.sql`](../../database/study/02_tv1_demo_hanh_vi.sql),
[`../../database/study/03_tv1_don_du_lieu_demo.sql`](../../database/study/03_tv1_don_du_lieu_demo.sql).
Phiếu/sản phẩm/vị trí fixture HS0001 có marker riêng, một dòng10 giá12500,
vị trí khô sức chứa100. Không dùng chứng từ người dùng, không sửa object ứng dụng.

| Lệnh/kiểm tra | Kết quả |
| --- | --- |
| Init database tạm `BlueStockBehaviorCheck01a17217`, chạy file00, file02 kèm assertions sau từng mục, file03 | Exit0; INSERT6+5 lỗi51820 không để lô; EXEC6+5 lỗi51820 rollback lô/tồn/sổ, phiếuNHAP; EXEC6+4 commit2lô, tồn10,2biến động; view2dòng giá trị75000/50000, function6/4; UPDATE bảo quản lỗi51825 giữKhô; hoàn tất lại lỗi51102 không tăng tồn. Cleanup đạt; database tạm đã DROP. |
| `docker compose exec -T db ... sqlcmd ... -d BlueStock -y 0 -Q 'SET STATISTICS XML ON; SELECT NgayNhap, MaPN, MaNCC, TrangThai FROM dbo.PHIEU_NHAP ORDER BY NgayNhap DESC, MaPN DESC; SET STATISTICS XML OFF;'` | Exit0; actual XML có RunTimeInformation, Index Scan dùng IX_PHIEU_NHAP_NGAY_MA, Ordered=1,0operatorSort. Chỉ truy vấn dữ liệu Docker, không thay dữ liệu/index. Plan lưu artifact `actual-index-plan.sqlplan`; không tuyên bố số đo cải thiện hiệu năng từ lượt này. |
| `pwsh -File scripts/verify.ps1` với JDK24, `git diff --check` | Exit0; 187 testJava,17frontend, Markdown/cú pháp đạt; chỉ cảnh báo LF/CRLF. Không chạy lại browser hoặc toàn bộ25SQL vì không đổi API/UI/object nghiệp vụ. |

Hướng dẫn trình bày kết quả tại
[`../development/TV1_DEMO_HANH_VI_SSMS.md`](../development/TV1_DEMO_HANH_VI_SSMS.md).
File01 tra metadata vẫn giữ làm tài liệu phụ. Chưa thao tác SSMS desktop tự
động; plan kiểm tra bằng SQL Server actual XML, ảnh SSMS do người học cung cấp.
