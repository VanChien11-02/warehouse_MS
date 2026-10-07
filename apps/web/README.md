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

JavaScript đã tách cấu hình điều hướng và dữ liệu mẫu khỏi điểm vào. Logic tương tác và CSS vẫn tập trung trong hai file lớn; backlog `GOV-03` cần tiếp tục tách theo feature trong [`../../docs/project/governance/WORKSTREAMS.md`](../../docs/project/governance/WORKSTREAMS.md), giữ hành vi hiện có và không đổi framework.

## Ngôn ngữ giao diện

Giao diện dùng phong cách editorial tiết chế lấy cảm hứng từ trang tham khảo trong `web_tham_khao/`: nền kem, xanh rừng, xanh sage và màu đất nung. Mật độ và hệ thống phân cấp được điều chỉnh cho một công cụ vận hành dữ liệu lớn. Font dùng font hệ thống có hỗ trợ đầy đủ tiếng Việt, không tải font hoặc thư viện từ CDN.

## Kết nối Spring Boot

`app.js` hiện dùng toàn bộ dữ liệu mẫu. `core/api-client.js` chuẩn bị session/CSRF cho adapter API, nhưng chưa được nối vào các màn hình. Biến `USE_DUMMY_DATA` chưa chuyển được giao diện sang backend. Luồng chứng từ/form demo không gửi HTTP. Backend có các route thật và payload trong [`../../contracts/`](../../contracts/), ví dụ `/api/san-pham`, `/api/phieu-nhap`, `/api/ton-kho`, `/api/phieu-xuat`. Dùng HTTP client theo contract để thử backend cho đến khi `FE-02` hoàn thành.

Khi nối giao diện, dùng origin `http://127.0.0.1:5174` khớp cấu hình CORS mặc định của API, xử lý session cookie/CSRF và loading/error/empty state. Tách dữ liệu mẫu và HTTP sau một adapter theo [`../../docs/project/governance/BACKLOG.md`](../../docs/project/governance/BACKLOG.md); không đổi URL rải rác trong form.

Danh sách resource/endpoint dự kiến nằm trong [`../../contracts/API_CATALOG.md`](../../contracts/API_CATALOG.md). Frontend không tự thêm field hoặc route chưa có contract được review.

## Quy tắc khi phát triển tiếp

- Không đưa quy tắc trừ/tăng tồn làm nguồn sự thật vào frontend.
- Mỗi màn hình có loading, empty, error và success state phù hợp.
- Kiểm tra desktop lẫn mobile; không cuộn ngang ngoài bảng dữ liệu có chủ đích.
- Nếu chuyển Vue 3 + TypeScript + Vite, thực hiện theo backlog/ADR riêng và giữ regression cho các hành vi baseline.
