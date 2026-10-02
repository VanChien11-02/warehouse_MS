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
- `app.js`: điều hướng theo vai trò, dữ liệu demo, bảng/phân trang và tương tác biểu mẫu.

## Ngôn ngữ giao diện

Giao diện dùng phong cách editorial tiết chế lấy cảm hứng từ trang tham khảo trong `web_tham_khao/`: nền kem, xanh rừng, xanh sage và màu đất nung. Mật độ và hệ thống phân cấp được điều chỉnh cho một công cụ vận hành dữ liệu lớn. Font dùng font hệ thống có hỗ trợ đầy đủ tiếng Việt, không tải font hoặc thư viện từ CDN.

## Kết nối Spring Boot

Mở `app.js` và đổi:

```js
const USE_DUMMY_DATA = false;
```

API mặc định: `http://localhost:8080/api`.

Endpoint đã chuẩn bị:

- `GET /api/sanpham`
- `POST /api/sanpham`
- `PUT /api/sanpham/{maSP}`
- `DELETE /api/sanpham/{maSP}`
- `GET /api/baocao/tonkho`

Backend cần cấu hình CORS đúng origin frontend. Khi có API contract chính thức, tên field và lỗi phải theo `contracts/`, không tự suy đoán ở UI.

## Quy tắc khi phát triển tiếp

- Không đưa quy tắc trừ/tăng tồn làm nguồn sự thật vào frontend.
- Mỗi màn hình có loading, empty, error và success state phù hợp.
- Kiểm tra desktop lẫn mobile; không cuộn ngang ngoài bảng dữ liệu có chủ đích.
- Nếu chuyển Vue 3 + TypeScript + Vite, thực hiện theo backlog/ADR riêng và giữ regression cho các hành vi baseline.
