# Frontend quản lý kho

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

JavaScript đã tách cấu hình điều hướng và dữ liệu mẫu khỏi điểm vào. Logic tương tác và CSS vẫn tập trung trong hai file lớn; backlog `GOV-03` cần tiếp tục tách theo feature trong [`../../docs/project/governance/WORKSTREAMS.md`](../../docs/project/governance/WORKSTREAMS.md), giữ hành vi hiện có và không đổi framework.

## Ngôn ngữ giao diện

Giao diện dùng phong cách editorial tiết chế lấy cảm hứng từ trang tham khảo trong `web_tham_khao/`: nền kem, xanh rừng, xanh sage và màu đất nung. Mật độ và hệ thống phân cấp được điều chỉnh cho một công cụ vận hành dữ liệu lớn. Font dùng font hệ thống có hỗ trợ đầy đủ tiếng Việt, không tải font hoặc thư viện từ CDN.

## Kết nối Spring Boot

Mở `http://127.0.0.1:5174/?mode=api#products` để đăng nhập và xem/tạo/sửa/xóa sản phẩm qua API theo [`../../contracts/session-rbac.md`](../../contracts/session-rbac.md) và [`../../contracts/san-pham.md`](../../contracts/san-pham.md). Chọn **Tồn kho** hoặc mở `?mode=api#inventory` để tra cứu lô/vị trí theo [`../../contracts/inventory-query.md`](../../contracts/inventory-query.md). Chọn **Báo cáo nhập–xuất–tồn** hoặc mở `?mode=api#reports` để xem biến động theo kỳ theo [`../../contracts/reporting.md`](../../contracts/reporting.md). Chế độ API chỉ hiển thị ba màn hình đã nối API. Cần API tại `http://127.0.0.1:8080` và frontend mở đúng origin `http://127.0.0.1:5174`; backend phải được cấu hình JDBC và bootstrap tài khoản trước.

Nếu port 8080 đang dùng, đặt `SERVER_PORT=8082` trong terminal API và mở frontend bằng `http://127.0.0.1:5174/?mode=api&apiPort=8082#products`. `apiPort` chỉ đổi cổng trên `127.0.0.1`; không gửi session sang host khác.

Nếu port 5174 cũng đang dùng, chạy `pwsh -File scripts/dev.ps1 -Target web -Port 5176`, đặt thêm `APP_WEB_ORIGIN=http://127.0.0.1:5176` cho API, rồi mở `http://127.0.0.1:5176/?mode=api&apiPort=8082#products`.

Mở `http://127.0.0.1:5174/` để xem prototype bằng dữ liệu mẫu. Các luồng chứng từ và màn hình danh mục khác vẫn là demo, chưa gửi HTTP. Dùng [`../../docs/testing/API_SMOKE.md`](../../docs/testing/API_SMOKE.md) với Postman để thử toàn bộ nghiệp vụ backend.

Frontend cần tiếp tục chuyển các màn hình theo [`../../docs/project/governance/BACKLOG.md`](../../docs/project/governance/BACKLOG.md). Dùng adapter HTTP và contract của từng resource, đồng thời giữ loading/error/empty state; không đổi URL rải rác trong form.

Danh sách resource/endpoint dự kiến nằm trong [`../../contracts/API_CATALOG.md`](../../contracts/API_CATALOG.md). Frontend không tự thêm field hoặc route chưa có contract được review.

## Quy tắc khi phát triển tiếp

- Không đưa quy tắc trừ/tăng tồn làm nguồn sự thật vào frontend.
- Mỗi màn hình có loading, empty, error và success state phù hợp.
- Kiểm tra desktop lẫn mobile; không cuộn ngang ngoài bảng dữ liệu có chủ đích.
- Nếu chuyển Vue 3 + TypeScript + Vite, thực hiện theo backlog/ADR riêng và giữ regression cho các hành vi baseline.
