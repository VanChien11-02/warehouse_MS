# Quản trị nhân viên và tài khoản

- Status: Accepted for BE implementation
- Scope: SEC-01, BR-SEC-001 đến BR-SEC-005
- Reviewer tích hợp: repository owner và frontend owner

Tất cả route trong contract này chỉ dành cho `Admin`, dùng session/CSRF chung. Mã `maNhanVien` và `maTaiKhoan` do người quản trị nhập, tối đa 6 chữ/số không dấu; mã đã cấp không đổi. Không xóa vật lý nhân viên hoặc tài khoản vì chứng từ và audit tham chiếu chúng. Một nhân viên có tối đa một tài khoản.

## Nhân viên

| Method | Route | Kết quả |
| --- | --- | --- |
| `GET` | `/api/nhan-vien?page=0&size=20` | Danh sách phân trang |
| `GET` | `/api/nhan-vien/{maNhanVien}` | Chi tiết |
| `POST` | `/api/nhan-vien` | `201`, `Location` và nhân viên mới |
| `PUT` | `/api/nhan-vien/{maNhanVien}` | Cập nhật thông tin và trạng thái làm việc |

Tạo: `{ "maNhanVien":"NV0002", "tenNhanVien":"Thủ kho", "soDienThoai":null, "gioiTinh":null, "ngaySinh":null, "diaChi":null, "luong":null, "ngayVaoLam":"2026-10-07" }`. `dangLamViec` mặc định `true`. `PUT` dùng các trường tương tự trừ mã và bắt buộc `dangLamViec`. `gioiTinh` nếu có chỉ nhận `Nam`, `Nữ`, `Khác`; `luong` không âm, tối đa `DECIMAL(19,4)`. Quản trị viên không thể tự chuyển `dangLamViec` của mình sang `false`.

## Tài khoản

| Method | Route | Kết quả |
| --- | --- | --- |
| `GET` | `/api/tai-khoan?page=0&size=20` | Danh sách phân trang |
| `GET` | `/api/tai-khoan/{maTaiKhoan}` | Chi tiết không có hash |
| `POST` | `/api/tai-khoan` | `201`, `Location` và tài khoản mới |
| `PUT` | `/api/tai-khoan/{maTaiKhoan}` | Đổi tên đăng nhập, role, trạng thái |
| `PUT` | `/api/tai-khoan/{maTaiKhoan}/mat-khau` | `204`, đặt lại mật khẩu |

Tạo: `{ "maTaiKhoan":"TK0002", "maNhanVien":"NV0002", "tenTaiKhoan":"staff", "role":"NVKHO", "matKhau":"<mật-khẩu-ít-nhất-12-ký-tự>" }`. Nhân viên phải đang làm việc. Role thuộc `ADMIN`, `QLKHO`, `NVKHO`, `KETOAN`. `PUT` chỉ nhận `tenTaiKhoan`, `role`, `trangThai`; không chuyển tài khoản sang nhân viên khác. Admin không thể tự khóa hoặc tự bỏ role `ADMIN`. Reset mật khẩu nhận `{ "matKhauMoi":"..." }`. Mật khẩu dài 12–72 ký tự và chỉ lưu BCrypt hash; response không có mật khẩu/hash.

Danh sách trả `{items,page,size,totalElements,totalPages}`, `page` bắt đầu 0, `size` 1–100. Lỗi chính: `404 EMPLOYEE_NOT_FOUND/ACCOUNT_NOT_FOUND`; `409 EMPLOYEE_CONFLICT/ACCOUNT_CONFLICT/EMPLOYEE_INACTIVE/SELF_DEACTIVATION_FORBIDDEN/SELF_ROLE_CHANGE_FORBIDDEN`; `422 INVALID_CODE/INVALID_ROLE/INVALID_GENDER/INVALID_USERNAME/INVALID_PASSWORD/INVALID_EMPLOYEE/INVALID_PAGINATION/VALIDATION_FAILED`. Anonymous nhận `401`, role khác nhận `403`.
