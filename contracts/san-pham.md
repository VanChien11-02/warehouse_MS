# Contract sản phẩm

- Status: Accepted for BE implementation
- Date: 2026-10-06
- Scope: CAT-01, BR-CAT-001, BR-CAT-002
- Owner triển khai: nhánh BE
- Reviewer tích hợp: repository owner và frontend owner

Base URL: `/api/san-pham`. Mọi request dùng session cookie; POST/PUT/DELETE cần CSRF token. `Admin` và `QuanLyKho` được ghi; cả bốn role được đọc.

| Method | Route | Hành vi | Thành công |
| --- | --- | --- | --- |
| `GET` | `/api/san-pham?page=0&size=20&q=` | Danh sách theo `MaSP` tăng dần, tìm mã/tên | `200` page envelope |
| `GET` | `/api/san-pham/{maSanPham}` | Chi tiết | `200` sản phẩm |
| `POST` | `/api/san-pham` | Tạo sản phẩm | `201` sản phẩm, `Location` |
| `PUT` | `/api/san-pham/{maSanPham}` | Sửa tên và giá mặc định | `200` sản phẩm |
| `DELETE` | `/api/san-pham/{maSanPham}` | Xóa sản phẩm chưa được tham chiếu | `204` |

Request tạo:

```json
{"maSanPham":"SP0001","tenSanPham":"Sản phẩm mẫu","maLoai":"LSP001","maDonViTinh":"DVT001","giaNhapMacDinh":10000.0000,"giaBanMacDinh":12000.0000}
```

Request sửa chỉ gồm `tenSanPham`, `giaNhapMacDinh`, `giaBanMacDinh`. Mã sản phẩm, loại và đơn vị tính không đổi sau khi tạo để giữ nghĩa dữ liệu lịch sử; nếu nhập sai trước khi có tham chiếu, xóa rồi tạo lại. Mã do client nhập, được trim/chuyển chữ hoa ở server và dài 1–6 ký tự chữ/số. Giá dùng `DECIMAL(19,4)`, không âm, JSON number.

Response sản phẩm thêm `tenLoai`, `tenDonViTinh` để frontend hiển thị; không chứa số tồn. Page envelope gồm `items`, `page`, `size`, `totalElements`, `totalPages`. `size` từ 1–100; `page` không âm. `q` là chuỗi tìm kiếm literal, tối đa 100 ký tự.

Lỗi dùng envelope chung: `404 PRODUCT_NOT_FOUND`; `409 PRODUCT_CODE_EXISTS` hoặc `PRODUCT_IN_USE`; `422 INVALID_REFERENCE` cho loại/đơn vị không tồn tại và `VALIDATION_FAILED` cho input không hợp lệ; `401` khi chưa đăng nhập, `403` khi role không có quyền hoặc thiếu CSRF. Database FK chặn xóa sản phẩm đã được chứng từ tham chiếu.

Chưa có trạng thái hoạt động trong ERD/schema hiện hành. Frontend demo phải bỏ trạng thái giả khi chuyển sang API; nếu cần ngừng dùng sản phẩm, thêm ADR và migration riêng.
