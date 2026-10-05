# Physical schema: danh mục và cấu trúc kho

Trạng thái: phần đầu của DB-01. Tài liệu này mô tả sáu bảng đã có trong `database/schema/`; các bảng nghiệp vụ còn lại chưa được triển khai.

| Bảng | Khóa chính | Khóa ngoại | Ràng buộc chính |
| --- | --- | --- | --- |
| `LOAI_SAN_PHAM` | `MaLoai CHAR(6)` | — | `TenLoai` bắt buộc; `YeuCauBaoQuan` thuộc Khô/Mát/Đông lạnh hoặc `NULL` |
| `DON_VI_TINH` | `MaDVT CHAR(6)` | — | `TenDVT` bắt buộc và duy nhất |
| `SAN_PHAM` | `MaSP CHAR(6)` | `MaLoai`, `MaDVT` | Tên bắt buộc; giá mặc định `DECIMAL(19,4)`, không âm |
| `KHO` | `MaKho CHAR(6)` | — | `TenKho` bắt buộc và duy nhất |
| `KHU_VUC` | `MaKhuVuc CHAR(6)` | `MaKho` | Tên duy nhất trong kho; loại Khô/Mát/Đông lạnh |
| `VI_TRI_KHO` | `MaViTri CHAR(6)` | `MaKhuVuc` | Tên duy nhất trong khu vực; sức chứa `INT` không âm; loại Lưu trữ/Lấy hàng/Hư hỏng |

Tên và mô tả dùng `NVARCHAR` để lưu tiếng Việt; mã dùng `CHAR(6)` theo tài liệu nguồn. `MoTa` dùng `NVARCHAR(1000)` thay cho kiểu `TEXT` cũ. Giá mặc định bằng 0 khi không cung cấp, nhưng giá nhập/xuất thực tế nằm trên dòng chứng từ.

Precision tiền theo phương án `DEC-008` trong `OPEN_DECISIONS.md`; trạng thái quyết định vẫn là `Open` cho đến khi nhóm xác nhận.

API sẽ dùng tên JSON trong `contracts/BASELINE.md`, chẳng hạn `MaSP` ↔ `maSanPham`, `MaViTri` ↔ `maViTri`. Các cột mã là chuỗi, không phải số tự tăng.

`SucChua` hiện là số nguyên theo ERD. Trước khi cho nhiều sản phẩm khác đơn vị dùng chung một vị trí, cần chốt đơn vị sức chứa hoặc quy tắc quy đổi; chưa được dùng tổng `SoLuongTon` khác đơn vị để kết luận vị trí còn chỗ.
