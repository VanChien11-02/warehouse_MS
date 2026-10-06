# Contract cấu trúc kho

- Status: Accepted for BE implementation
- Date: 2026-10-07
- Scope: LOC-01, BR-CAT-001, BR-WHS-001
- Owner triển khai: nhánh BE
- Reviewer tích hợp: repository owner và frontend owner

Hiện có API `/api/kho`, `/api/khu-vuc` và `/api/vi-tri`. Mọi request dùng session cookie; POST/PUT/DELETE cần CSRF token. Cả bốn role được đọc; `Admin` và `QuanLyKho` được ghi.

Mỗi resource có `GET /` (danh sách), `GET /{ma}` (chi tiết), `POST /` (tạo), `PUT /{ma}` (sửa), `DELETE /{ma}` (xóa). Thành công trả `200`, `200`, `201` kèm `Location`, `200`, `204`. Danh sách hỗ trợ `page=0&size=20&q=`, sắp theo mã tăng dần; khu vực hỗ trợ thêm `maKho`, vị trí hỗ trợ `maKho` và `maKhuVuc` để lọc. Page envelope gồm `items`, `page`, `size`, `totalElements`, `totalPages`. `size` từ 1–100, `page` không âm, `q` tìm literal trong mã/tên và dài tối đa 100 ký tự.

Tạo kho:

```json
{"maKho":"KHO001","tenKho":"Kho chính","diaChi":"Hà Nội"}
```

Sửa kho chỉ gồm `tenKho`, `diaChi`. Tên kho bắt buộc, tối đa 255 ký tự và duy nhất; địa chỉ có thể `null`, tối đa 255 ký tự. Response có cùng ba trường.

Tạo khu vực:

```json
{"maKhuVuc":"KV0001","maKho":"KHO001","tenKhuVuc":"Khu khô","loaiKhuVuc":"Khô"}
```

Sửa khu vực chỉ gồm `tenKhuVuc`. Tên bắt buộc, tối đa 255 ký tự và duy nhất trong một kho. `loaiKhuVuc` chính xác một trong `Khô`, `Mát`, `Đông lạnh`; response khu vực thêm `tenKho` để hiển thị. Mã và kho cha không đổi sau khi tạo. Loại khu vực cũng không đổi qua API để không làm sai nghĩa các vị trí và lô đã ghi sổ.

Mã do client nhập, trim/chuyển chữ hoa ở server và dài 1–6 ký tự chữ/số. Xóa chỉ khi chưa có dữ liệu con hoặc tham chiếu; FK của SQL Server là chốt chặn cuối.

Tạo vị trí:

```json
{"maViTri":"VT0001","maKhuVuc":"KV0001","tenViTri":"Kệ 1","sucChua":100,"loaiViTri":"Lưu trữ"}
```

Sửa vị trí chỉ gồm `tenViTri`. Tên bắt buộc, tối đa 255 ký tự và duy nhất trong một khu vực. `sucChua` là số nguyên không âm theo đơn vị tính gốc; `loaiViTri` chính xác một trong `Lưu trữ`, `Lấy hàng`, `Hư hỏng`. Response thêm `tenKhuVuc`, `maKho`, `tenKho`, `loaiKhuVuc` để hiển thị và kiểm tra trước khi nhập hàng. Khu vực cha, sức chứa và loại vị trí không đổi qua API CRUD sau khi tạo; điều chỉnh sức chứa về sau cần use case riêng kiểm tra tồn hiện tại.

Lỗi dùng envelope chung: `404 WAREHOUSE_NOT_FOUND`/`AREA_NOT_FOUND`/`POSITION_NOT_FOUND`; `409 WAREHOUSE_CODE_EXISTS`, `WAREHOUSE_NAME_EXISTS`, `WAREHOUSE_IN_USE`, `AREA_CODE_EXISTS`, `AREA_NAME_EXISTS`, `AREA_IN_USE`, `POSITION_CODE_EXISTS`, `POSITION_NAME_EXISTS`, `POSITION_IN_USE`; `422 INVALID_WAREHOUSE`, `INVALID_AREA`, `INVALID_CODE`, `INVALID_PAGINATION`, `INVALID_QUERY`, `VALIDATION_FAILED`; `401` khi chưa đăng nhập, `403` khi thiếu quyền hoặc CSRF.

Khi ghi sổ tồn, procedure phải kiểm tra sức chứa và loại bảo quản trong cùng transaction theo ADR 0004; CRUD cấu trúc không tự quyết định số tồn.
