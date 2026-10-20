# Contract session và role

- Status: Accepted for BE implementation
- Date: 2026-10-06
- Scope: SEC-01, BR-SEC-001 đến BR-SEC-005
- Owner triển khai: nhánh BE
- Reviewer tích hợp: repository owner và frontend owner

Ứng dụng dùng session cookie `JSESSIONID` với `HttpOnly`. Frontend gọi API bằng `credentials: "include"` từ origin được cấu hình chính xác. Mọi request ghi dữ liệu cần CSRF token trong header `X-CSRF-TOKEN`; token lấy bằng `GET /api/auth/csrf` và phải lấy lại sau khi session hết hạn hoặc đăng xuất. Cookie và token không lưu trong `localStorage`.

| Method | Route | Quyền | Request | Kết quả |
| --- | --- | --- | --- | --- |
| `GET` | `/api/auth/csrf` | Public | — | `200` với `token`, `headerName` |
| `POST` | `/api/auth/dang-nhap` | Public + CSRF | `tenTaiKhoan`, `matKhau` | `200` với thông tin tài khoản và session cookie |
| `GET` | `/api/auth/me` | Đã đăng nhập | — | `200` với thông tin tài khoản |
| `POST` | `/api/auth/dang-xuat` | Đã đăng nhập + CSRF | — | `204`, hủy session |
| `PUT` | `/api/auth/doi-mat-khau` | Đã đăng nhập + CSRF | `matKhauCu`, `matKhauMoi` | `204`, cập nhật BCrypt hash |

Ví dụ request đăng nhập:

```json
{"tenTaiKhoan":"quanly.kho","matKhau":"<mat-khau-nhap-tu-nguoi-dung>"}
```

Response của đăng nhập và `/me`:

```json
{"maTaiKhoan":"TK0001","maNhanVien":"NV0001","tenNhanVien":"Nguyễn An","tenTaiKhoan":"quanly.kho","role":"QLKHO"}
```

`role` là một trong `ADMIN`, `QLKHO`, `NVKHO`, `KETOAN`, tương ứng `Admin`, `QuanLyKho`, `NhanVienKho`, `KeToan`. API không trả password hoặc hash. Tài khoản bị khóa hoặc nhân viên đã nghỉ không đăng nhập được; lỗi đăng nhập không tiết lộ nguyên nhân cụ thể.

Response lỗi dùng envelope trong `BASELINE.md`. `401 INVALID_CREDENTIALS` cho thông tin đăng nhập sai hoặc tài khoản không dùng được; `401 UNAUTHORIZED` khi chưa có session; `403 FORBIDDEN` cho thiếu quyền hoặc CSRF; `400 MALFORMED_JSON` cho JSON sai; `422 VALIDATION_FAILED` cho trường bắt buộc rỗng.

Đổi mật khẩu kiểm tra mật khẩu cũ với hash mới nhất trong database dưới khóa transaction; mật khẩu mới dài 12–72 ký tự và phải khác mật khẩu cũ. Sai mật khẩu cũ/tài khoản không còn hoạt động trả `401 INVALID_CREDENTIALS`; trùng mật khẩu cũ trả `422 PASSWORD_REUSED`. Request/response không chứa hash. Quản trị nhân viên và tài khoản nằm trong [`identity-admin.md`](identity-admin.md). Backend từ chối mọi route chưa khai báo quyền.

Khởi tạo lần đầu dùng `scripts/bootstrap-admin.ps1` sau khi `BlueStock` được tạo và kết nối JDBC hoạt động. Lệnh yêu cầu mật khẩu qua terminal, tạo `NHAN_VIEN.NV0001` và `TAI_KHOAN.TK0001` với role `ADMIN` và BCrypt hash trong một transaction. Lệnh từ chối khi đã có tài khoản; không có mật khẩu mặc định trong repository.
