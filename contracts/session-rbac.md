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

Tạo tài khoản, đổi mật khẩu và chi tiết quyền từng endpoint nghiệp vụ sẽ được bổ sung vào contract khi triển khai. Backend từ chối mọi route chưa khai báo quyền.
