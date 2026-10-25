# Frontend quản lý kho

Trong chế độ API, **Phiếu nhập kho → Lịch sử nhập kho** dành cho QLKHO/KETOAN
đọc từng lô đã nhập từ `vw_LichSuNhapKho` qua API. Lọc theo mã phiếu, sản phẩm,
nhà cung cấp và ngày hoàn tất UTC; phân trang 20 lô/trang, bấm mã phiếu mở
chứng từ gốc. Tab giữ nháp khi chuyển qua lại; có loading/empty/error/retry.
Module riêng `features/live-inbound-history.js`, adapter tại `data/document-api.js`.

Baseline hiện dùng HTML5, CSS3 và Vanilla JavaScript, không có thư viện ngoài.

## Chạy

Từ root repository:

```powershell
pwsh -File scripts/dev.ps1 -Target web
```

Mở `http://127.0.0.1:5174`.

## Phạm vi giao diện demo

- Sidebar phân nhóm đầy đủ cho Tổng quan, Hàng hóa, Kho bãi, Đối tác, Giao dịch và Hệ thống.
- Có bộ chuyển vai trò demo cho Quản trị viên, Quản lý kho và Nhân viên kho. Đây chỉ là lớp trình bày; backend vẫn là nguồn sự thật phân quyền.
- Dashboard có chỉ số vận hành, biểu đồ nhập/xuất, hàng chờ xử lý và chứng từ gần đây.
- Form master-detail dùng chung cho phiếu nhập, xuất và chuyển kho; có tổng số lượng, tổng giá trị và trạng thái từng dòng.
- Phiếu kiểm kê hỗ trợ so sánh số lượng hệ thống/thực tế; phiếu trả hàng phân loại Tốt/Hư hỏng.
- Bảng danh mục có tìm kiếm, lọc, phân trang và trạng thái; dữ liệu hiện tại được ghi rõ là dữ liệu demo.

## File chính

- `index.html`: app shell, các màn hình nghiệp vụ và biểu mẫu.
- `styles.css`: design tokens, trạng thái và bố cục responsive.
- `app.js`: khởi tạo giao diện, bảng/phân trang và tương tác biểu mẫu.
- `core/navigation.js`: cấu hình vai trò demo, menu và tiêu đề màn hình.
- `core/api-client.js`: HTTP client giữ session cookie và CSRF token trong bộ nhớ cho chế độ API.
- `data/demo.js`: dữ liệu giả của danh mục, tồn, kiểm kê và báo cáo.
- `data/product-api.js`: adapter theo contract cho CRUD sản phẩm, loại và đơn vị tính.
- `features/live-products.js`: màn hình sản phẩm dùng API thật.
- `data/inventory-api.js`: adapter tra cứu tồn theo contract.
- `features/live-inventory.js`: màn hình tồn kho dùng API thật.
- `data/report-api.js`: adapter báo cáo nhập–xuất–tồn theo contract.
- `features/live-report.js`: màn hình báo cáo dùng API thật.
- `data/document-api.js`: adapter phiếu nhập, phiếu xuất và gợi ý FEFO.
- `features/live-documents.js` và `data/document-models.js`: danh sách, form nhiều dòng, sửa/hủy nháp và hoàn tất năm loại chứng từ qua API.
- `data/identity-api.js` và `features/live-identity.js`: quản trị nhân viên/tài khoản bằng API cho Admin.
- `data/master-api.js` và `features/live-masters.js`: CRUD loại, đơn vị, kho, khu vực, vị trí và đối tác; gán/bỏ sản phẩm liên kết.
- `features/live-permissions.js`: ma trận quyền tải từ backend và điều hướng tới gán vai trò tài khoản.
- `data/insight-api.js` và `features/live-insights.js`: tổng quan theo vai trò, lô sắp hết hạn, chênh lệch kiểm kê và audit.

JavaScript đã tách cấu hình điều hướng và dữ liệu mẫu khỏi điểm vào. Logic tương tác và CSS vẫn tập trung trong hai file lớn; backlog `GOV-03` cần tiếp tục tách theo feature trong [`../../docs/project/governance/WORKSTREAMS.md`](../../docs/project/governance/WORKSTREAMS.md), giữ hành vi hiện có và không đổi framework.

## Ngôn ngữ giao diện

Giao diện dùng phong cách editorial tiết chế lấy cảm hứng từ trang tham khảo trong `web_tham_khao/`: nền kem, xanh rừng, xanh sage và màu đất nung. Mật độ và hệ thống phân cấp được điều chỉnh cho một công cụ vận hành dữ liệu lớn. Font dùng font hệ thống có hỗ trợ đầy đủ tiếng Việt, không tải font hoặc thư viện từ CDN.

## Kết nối Spring Boot

Mở `http://127.0.0.1:5174/?mode=api#products` để đăng nhập và xem/tạo/sửa/xóa sản phẩm qua API theo [`../../contracts/session-rbac.md`](../../contracts/session-rbac.md) và [`../../contracts/san-pham.md`](../../contracts/san-pham.md). Chọn **Phiếu nhập** và **Phiếu xuất** để tạo nháp, tải lại phiếu bằng mã, hoàn tất hoặc hủy theo quyền trong [`../../contracts/inbound-completion.md`](../../contracts/inbound-completion.md) và [`../../contracts/outbound-fefo-completion.md`](../../contracts/outbound-fefo-completion.md). Chọn **Tồn kho** để tra cứu lô/vị trí theo [`../../contracts/inventory-query.md`](../../contracts/inventory-query.md), và **Báo cáo nhập–xuất–tồn** để xem biến động theo kỳ theo [`../../contracts/reporting.md`](../../contracts/reporting.md). Cần API tại `http://127.0.0.1:8080` và frontend mở đúng origin `http://127.0.0.1:5174`; backend phải được cấu hình JDBC và bootstrap tài khoản trước.

Menu chế độ API lấy role từ phiên đăng nhập. `ADMIN` chỉ quản trị nhân viên, tài khoản và quyền hạn. `QLKHO` có đủ màn hình như vai trò quản lý demo: tổng quan, danh mục, kho/khu vực/vị trí, đối tác, tồn kho, nhập/xuất/chuyển/kiểm kê/trả hàng và báo cáo. `NVKHO` tra cứu tồn và lập/sửa/hủy nháp phiếu nhập, phiếu xuất. `KETOAN` đọc chứng từ, tồn và báo cáo giá trị/chênh lệch; trên phiếu nhập/xuất đã hoàn tất có thể xác nhận đối soát giá trị một lần hoặc ghi nhận sai lệch. Hoàn tất phiếu chỉ dành cho `QLKHO`; backend kiểm tra độc lập. Nhân viên/tài khoản dùng ngừng làm việc/khóa, không xóa vật lý. Xem ma trận tại [`../../contracts/permissions.md`](../../contracts/permissions.md) và [`../../contracts/accounting-reconciliation.md`](../../contracts/accounting-reconciliation.md).

Chứng từ API có danh sách phân trang/lọc trạng thái và tải theo mã. Form nhập/xuất/chuyển/trả hàng hỗ trợ nhiều dòng, lưu/sửa nháp và hủy. Phiếu nhập có bảng phân bổ riêng, cho phép chia sản phẩm vào nhiều vị trí/lô với ngày sản xuất/hạn dùng; tổng phân bổ do server kiểm tra khi hoàn tất. Xuất có tra cứu FEFO; gợi ý không tự ghi đè dòng nháp. Kiểm kê tạo snapshot tại server, nhập số đếm/lý do từng lô và cho thêm lô đã tồn tại. Các dòng kiểm kê được lưu tuần tự qua endpoint từng dòng; nếu lỗi giữa chừng, các dòng đã lưu vẫn là nháp và có thể tải lại/tiếp tục. Chỉ hoàn tất mới đổi tồn nguyên tử. Chứng từ hoàn tất/đã hủy chỉ đọc.

Nếu port 8080 đang dùng, đặt `SERVER_PORT=8082` trong terminal API và mở frontend bằng `http://127.0.0.1:5174/?mode=api&apiPort=8082#products`. `apiPort` chỉ đổi cổng trên `127.0.0.1`; không gửi session sang host khác.

Nếu port 5174 cũng đang dùng, chạy `pwsh -File scripts/dev.ps1 -Target web -Port 5176`, đặt thêm `APP_WEB_ORIGIN=http://127.0.0.1:5176` cho API, rồi mở `http://127.0.0.1:5176/?mode=api&apiPort=8082#products`.

Mở `http://127.0.0.1:5174/` để xem prototype bằng dữ liệu mẫu. Trong `mode=api`, các màn hình được hiển thị theo phiên đăng nhập đều dùng API; bảng điều khiển hiển thị chỉ số đếm, biểu đồ khối lượng phiếu và lối vào theo vai trò từ dữ liệu thật. Chưa có API tạo vai trò tùy ý: Admin gán một trong bốn vai trò có sẵn qua tài khoản. Dùng [`../../docs/testing/API_SMOKE.md`](../../docs/testing/API_SMOKE.md) để kiểm tra trên database thật.

Frontend cần tiếp tục chuyển các màn hình theo [`../../docs/project/governance/BACKLOG.md`](../../docs/project/governance/BACKLOG.md). Dùng adapter HTTP và contract của từng resource, đồng thời giữ loading/error/empty state; không đổi URL rải rác trong form.

## Kiểm tra trình duyệt

Trigger bảo quản mới dùng ngay form **Loại sản phẩm**: mở loại đã có lô, đổi
**Yêu cầu bảo quản** từ Khô sang Mát rồi **Lưu**. Lỗi 409 từ trigger giữ dialog
mở và database giữ giá trị cũ; đổi lại Khô rồi sửa tên/mô tả vẫn lưu được. Loại
chưa có lô được đổi yêu cầu. Không có màn hình thực hành riêng.

`node scripts/verify-category-storage-ui.mjs` kiểm tra form này bằng tài khoản
`CATEGORY_TEST_USERNAME`/`CATEGORY_TEST_PASSWORD`, loại có lô và yêu cầu Khô
`CATEGORY_TEST_USED`, loại chưa có lô `CATEGORY_TEST_UNUSED`. Dùng dữ liệu test
riêng vì ca hợp lệ thực sự sửa tên/mô tả và yêu cầu bảo quản. Cấu hình
Playwright/URL/thư mục ảnh dùng như các browser gate bên dưới.

Ngay trên form Phiếu nhập, nhập một dòng 10 đơn vị rồi phân bổ 6 + 5 vào các
vị trí hợp lệ, đủ sức chứa. Bấm **Hoàn tất**: trigger trên `LO_HANG` chặn lượng
vượt, API trả `ALLOCATION_EXCEEDS_LINE`, UI giữ phiếu nháp và hiển thị cách sửa.
Phân bổ 6 + 3 trả `ALLOCATION_INCOMPLETE` từ procedure; sửa thành 6 + 4 hoàn tất
được. Không có màn hình thực hành hay endpoint SQL thử trong ứng dụng.
Xem [ranh giới procedure/trigger](../../docs/architecture/adr/0008-inbound-integrity-boundary.md).

`node scripts/verify-inbound-rollback-ui.mjs` kiểm tra form nhập thật với
`INBOUND_TEST_USERNAME`, `INBOUND_TEST_PASSWORD` của Quản lý kho. Dùng dữ liệu
test riêng, vị trí đủ sức chứa; script tạo và hoàn tất phiếu thật. Có thể đặt
`INBOUND_TEST_PRODUCT`, `INBOUND_TEST_SUPPLIER`, `INBOUND_TEST_POSITION_A`,
`INBOUND_TEST_POSITION_B`, `INBOUND_TEST_BAD_POSITION`; mặc định dùng seed.
Các biến Playwright/URL/thư mục ảnh dùng như bài browser gate bên dưới.

`scripts/verify-web-parity.mjs` dùng Playwright được cài ngoài frontend. Đặt
`PLAYWRIGHT_PATH` tới module Playwright, tùy chọn `PLAYWRIGHT_CHANNEL=msedge`,
`WEB_TEST_URL` (mặc định `http://127.0.0.1:5174`) và `WEB_TEST_OUTPUT` để lưu ảnh.
Chạy `node scripts/verify-web-parity.mjs` khi web server đang chạy. Bài kiểm tra
giả lập HTTP, không ghi database; cổng chuẩn vẫn là `pwsh -File scripts/verify.ps1`.

Danh sách resource/endpoint dự kiến nằm trong [`../../contracts/API_CATALOG.md`](../../contracts/API_CATALOG.md). Frontend không tự thêm field hoặc route chưa có contract được review.

## Quy tắc khi phát triển tiếp

- Không đưa quy tắc trừ/tăng tồn làm nguồn sự thật vào frontend.
- Mỗi màn hình có loading, empty, error và success state phù hợp.
- Kiểm tra desktop lẫn mobile; không cuộn ngang ngoài bảng dữ liệu có chủ đích.
- Nếu chuyển Vue 3 + TypeScript + Vite, thực hiện theo backlog/ADR riêng và giữ regression cho các hành vi baseline.
