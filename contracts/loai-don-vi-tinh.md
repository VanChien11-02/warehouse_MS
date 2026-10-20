# Contract loại sản phẩm và đơn vị tính

- Status: Accepted for BE implementation
- Date: 2026-10-07
- Scope: CAT-01, BR-CAT-001, BR-WHS-003
- Owner triển khai: nhánh BE
- Reviewer tích hợp: repository owner và frontend owner

Base URL: `/api/loai-san-pham` và `/api/don-vi-tinh`. Mọi request dùng session cookie. POST/PUT/DELETE cần CSRF token. Cả bốn role được đọc; `Admin` và `QuanLyKho` được ghi.

Mỗi resource có `GET /` để lấy danh sách, `GET /{ma}` để lấy chi tiết, `POST /` để tạo, `PUT /{ma}` để sửa và `DELETE /{ma}` để xóa. Thành công lần lượt trả `200`, `200`, `201` kèm `Location`, `200`, `204`.

Danh sách hỗ trợ `page=0&size=20&q=`, sắp theo mã tăng dần. `size` từ 1 đến 100, `page` không âm, `q` tìm literal trong mã hoặc tên và dài tối đa 100 ký tự. Response dùng page envelope `items`, `page`, `size`, `totalElements`, `totalPages` như contract sản phẩm.

Request tạo loại sản phẩm:

```json
{"maLoai":"LSP001","tenLoai":"Đồ khô","moTa":null,"yeuCauBaoQuan":"Khô"}
```

Request sửa không chứa `maLoai`. `tenLoai` bắt buộc, tối đa 255 ký tự; `moTa` có thể `null`, tối đa 1000 ký tự; `yeuCauBaoQuan` có thể `null` hoặc chính xác một trong `Khô`, `Mát`, `Đông lạnh`. Response có cùng bốn trường. Giá trị này được kiểm tra lại khi ghi sổ vào vị trí kho theo BR-WHS-003.

Request tạo đơn vị tính:

```json
{"maDonViTinh":"DVT001","tenDonViTinh":"Hộp"}
```

Request sửa chỉ chứa `tenDonViTinh`. Tên bắt buộc, tối đa 100 ký tự và duy nhất trong database. Response có cùng hai trường. Mã do client nhập, trim/chuyển chữ hoa ở server và dài 1–6 ký tự chữ/số; mã không đổi sau khi tạo.

Lỗi dùng envelope chung: `404 CATEGORY_NOT_FOUND`/`UNIT_NOT_FOUND`; `409 CATEGORY_CODE_EXISTS`, `UNIT_CODE_EXISTS`, `UNIT_NAME_EXISTS`, `CATEGORY_IN_USE`, `UNIT_IN_USE`; `422 INVALID_CODE`, `INVALID_PAGINATION`, `INVALID_QUERY`, `VALIDATION_FAILED`; `401` khi chưa đăng nhập và `403` khi thiếu quyền hoặc CSRF. FK chặn xóa loại/đơn vị đã được sản phẩm hoặc chứng từ tham chiếu.

Schema hiện hành không có trạng thái hoạt động của loại hoặc đơn vị; API không phát sinh trạng thái giả.
