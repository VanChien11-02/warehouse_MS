# Danh mục API dự kiến

> Trạng thái: **Draft**. File này là inventory để không bỏ sót hoặc đặt endpoint trùng nhau. Request/response chi tiết phải nằm trong contract riêng hoặc OpenAPI sau khi nhóm chốt baseline.

## Quy ước chung

- Base URL local: `http://127.0.0.1:8080/api`.
- URL trong bảng dùng kebab-case theo ADR 0003.
- JSON dùng `camelCase`; enum và mã lỗi dùng `UPPER_SNAKE_CASE`.
- Mọi danh sách lớn hỗ trợ phân trang/lọc phù hợp.
- Mọi endpoint ghi dữ liệu yêu cầu role và validation phía server.
- Endpoint `hoan-tat` phải idempotent theo nghĩa nghiệp vụ: lần gọi sau không ghi sổ thêm và trả conflict có cấu trúc.

## Platform và auth

| Method | Route dự kiến | Mục đích | Quyền dự kiến | Backlog |
| --- | --- | --- | --- | --- |
| `GET` | `/api/health` | Liveness của tiến trình; response `{"status":"UP"}` | Public | BE-01 |
| `GET` | `/actuator/health` | Readiness gồm kết nối database khi cấu hình | Public | BE-01 |
| `GET` | `/api/auth/csrf` | Cấp token CSRF cho session hiện tại | Public | SEC-01 |
| `POST` | `/api/auth/dang-nhap` | Xác thực và tạo session | Public | SEC-01 |
| `POST` | `/api/auth/dang-xuat` | Kết thúc phiên | Authenticated | SEC-01 |
| `GET` | `/api/auth/me` | Thông tin user/role hiện tại | Authenticated | SEC-01 |
| `PUT` | `/api/auth/doi-mat-khau` | Đổi mật khẩu của user hiện tại | Authenticated | SEC-01 |
| `GET/POST/PUT` | `/api/nhan-vien` | Danh sách/tạo/cập nhật nhân viên | Admin; quyền quản lý cần chốt | SEC-01 |
| `GET/POST/PUT` | `/api/tai-khoan` | Quản lý tài khoản, role và trạng thái | Admin | SEC-01 |
| `GET` | `/api/audit` | Tra cứu nhật ký | Admin/QuanLyKho giới hạn | AUD-01 |

Không thiết kế endpoint trả password hash hoặc dữ liệu xác thực nội bộ.

Payload và role của các endpoint session đã triển khai nằm trong [`session-rbac.md`](session-rbac.md).

## Danh mục và cấu trúc kho

| Resource | Route dự kiến | Hành vi | Owner |
| --- | --- | --- | --- |
| Loại sản phẩm | `/api/loai-san-pham` | CRUD, tìm kiếm, trạng thái nếu có | TV1 |
| Đơn vị tính | `/api/don-vi-tinh` | CRUD | TV1 |
| Sản phẩm | `/api/san-pham` | CRUD, tìm kiếm, lọc loại/trạng thái | TV1 |
| Nhà cung cấp | `/api/nha-cung-cap` | CRUD và mapping sản phẩm | TV1 |
| Đối tác nhận hàng | `/api/doi-tac-nhan-hang` | CRUD và mapping sản phẩm | TV1 |
| Kho | `/api/kho` | CRUD | TV1 |
| Khu vực | `/api/khu-vuc` | CRUD, lọc theo kho | TV1 |
| Vị trí | `/api/vi-tri` | CRUD, lọc khu vực/loại/sức chứa | TV1 |

CRUD không đồng nghĩa cho phép xóa dữ liệu đã được chứng từ tham chiếu. Chính sách deactivate/soft delete cần được chốt theo resource.

## Nhập kho và tồn

| Method | Route dự kiến | Mục đích | Quyền dự kiến |
| --- | --- | --- | --- |
| `GET` | `/api/phieu-nhap` | Danh sách/lọc phiếu | Nhân viên kho trở lên; Kế toán đọc |
| `POST` | `/api/phieu-nhap` | Tạo phiếu nháp | NhanVienKho/QuanLyKho |
| `GET` | `/api/phieu-nhap/{maPhieuNhap}` | Chi tiết phiếu | Theo role |
| `PUT` | `/api/phieu-nhap/{maPhieuNhap}` | Sửa header/dòng khi còn nháp | NhanVienKho/QuanLyKho |
| `POST` | `/api/phieu-nhap/{maPhieuNhap}/hoan-tat` | Tạo lô, put-away, tăng tồn | Quyền hoàn tất cần chốt |
| `POST` | `/api/phieu-nhap/{maPhieuNhap}/huy` | Hủy phiếu nháp | Quyền cần chốt |
| `GET` | `/api/ton-kho` | Lọc theo kho/vị trí/sản phẩm/lô/hạn | Authenticated theo role |
| `GET` | `/api/lo-hang` | Tra cứu lô và hạn dùng | Authenticated theo role |

Payload hoàn tất nhập phải chỉ ra cách phân bổ lô vào vị trí nếu thông tin đó chưa nằm trong phiếu. Hình thức payload cụ thể cần contract riêng.

## Xuất kho

| Method | Route dự kiến | Mục đích | Quyền dự kiến |
| --- | --- | --- | --- |
| `GET` | `/api/phieu-xuat` | Danh sách/lọc phiếu | Theo role |
| `POST` | `/api/phieu-xuat` | Tạo phiếu nháp | NhanVienKho/QuanLyKho |
| `GET` | `/api/phieu-xuat/{maPhieuXuat}` | Chi tiết phiếu | Theo role |
| `PUT` | `/api/phieu-xuat/{maPhieuXuat}` | Sửa phiếu nháp | NhanVienKho/QuanLyKho |
| `GET` | `/api/phieu-xuat/{maPhieuXuat}/goi-y-fefo` | Gợi ý lô/vị trí | NhanVienKho/QuanLyKho |
| `POST` | `/api/phieu-xuat/{maPhieuXuat}/hoan-tat` | Kiểm tra và trừ tồn nguyên tử | Quyền hoàn tất cần chốt |
| `POST` | `/api/phieu-xuat/{maPhieuXuat}/huy` | Hủy phiếu nháp | Quyền cần chốt |

Gợi ý FEFO không giữ chỗ tồn vĩnh viễn. Khi hoàn tất phải kiểm tra/khóa lại tồn trong transaction.

## Chuyển kho, kiểm kê và trả hàng

| Resource | Route chính | Hành vi đặc biệt |
| --- | --- | --- |
| Phiếu chuyển | `/api/phieu-chuyen` | CRUD nháp, `/{id}/hoan-tat`, `/{id}/huy` |
| Phiếu kiểm kê | `/api/phieu-kiem-ke` | Tạo snapshot, nhập thực tế, `/{id}/hoan-tat` |
| Phiếu trả hàng | `/api/phieu-tra-hang` | Tạo từ phiếu xuất, kiểm tra giới hạn trả, `/{id}/hoan-tat` |

Mỗi resource cần contract riêng cho header/detail, trạng thái, quyền, validation và lỗi transaction.

## Báo cáo

| Method | Route dự kiến | Bộ lọc chính | Role |
| --- | --- | --- | --- |
| `GET` | `/api/bao-cao/ton-kho` | kho, vị trí, sản phẩm, lô, ngày hết hạn | QuanLyKho/KeToan; role khác giới hạn |
| `GET` | `/api/bao-cao/nhap-xuat` | từ ngày, đến ngày, sản phẩm/kho | QuanLyKho/KeToan |
| `GET` | `/api/bao-cao/lo-sap-het-han` | số ngày, kho | QuanLyKho/NhanVienKho |
| `GET` | `/api/bao-cao/chenh-lech-kiem-ke` | kỳ/kho/vị trí | QuanLyKho/KeToan |

Nguồn giá và boundary thời gian phải được chốt trước báo cáo giá trị.

## Contract chi tiết cần tạo theo ưu tiên

1. `session-rbac`.
2. `san-pham` và pagination/error chung.
3. `warehouse-location`.
4. `inbound-completion`.
5. `inventory-query`.
6. `outbound-fefo-completion`.
7. `transfer`, `inventory-count`, `returning`.
8. `reporting` và `audit`.

Mỗi contract chi tiết phải có:

- trạng thái, owner và reviewer;
- endpoint, role và permission;
- request/response mẫu;
- validation và business rule ID;
- error code/HTTP status;
- pagination/date/decimal semantics;
- breaking/non-breaking history.
