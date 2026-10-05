# Physical schema: identity, danh mục và cấu trúc kho

Trạng thái: phần đầu của DB-01. Tài liệu này mô tả chín bảng đã có trong `database/schema/`; các bảng chứng từ và tồn kho còn lại chưa được triển khai.

Database baseline là `BlueStock`, schema ứng dụng là `dbo` theo ADR 0003.

| Bảng | Khóa chính | Khóa ngoại | Ràng buộc chính |
| --- | --- | --- | --- |
| `ROLE` | `MaRole CHAR(6)` | — | `TenRole` bắt buộc và duy nhất; seed bốn role ứng dụng |
| `NHAN_VIEN` | `MaNV CHAR(6)` | — | `TenNV`, `NgayVaoLam` bắt buộc; `Luong DECIMAL(19,4)` không âm; `DangLamViec` mặc định 1 |
| `TAI_KHOAN` | `MaTK CHAR(6)` | `MaNV`, `MaRole` | `MaNV` và `TenTK` duy nhất; `MatKhauHash` bắt buộc; `TrangThai` mặc định 1 |
| `LOAI_SAN_PHAM` | `MaLoai CHAR(6)` | — | `TenLoai` bắt buộc; `YeuCauBaoQuan` thuộc Khô/Mát/Đông lạnh hoặc `NULL` |
| `DON_VI_TINH` | `MaDVT CHAR(6)` | — | `TenDVT` bắt buộc và duy nhất |
| `SAN_PHAM` | `MaSP CHAR(6)` | `MaLoai`, `MaDVT` | Tên bắt buộc; giá mặc định `DECIMAL(19,4)`, không âm |
| `KHO` | `MaKho CHAR(6)` | — | `TenKho` bắt buộc và duy nhất |
| `KHU_VUC` | `MaKhuVuc CHAR(6)` | `MaKho` | Tên duy nhất trong kho; loại Khô/Mát/Đông lạnh |
| `VI_TRI_KHO` | `MaViTri CHAR(6)` | `MaKhuVuc` | Tên duy nhất trong khu vực; sức chứa `INT` không âm; loại Lưu trữ/Lấy hàng/Hư hỏng |

Tên và mô tả dùng `NVARCHAR` để lưu tiếng Việt; mã dùng `CHAR(6)` theo tài liệu nguồn. `MoTa` dùng `NVARCHAR(1000)` thay cho kiểu `TEXT` cũ. Giá mặc định bằng 0 khi không cung cấp, nhưng giá nhập/xuất thực tế nằm trên dòng chứng từ.

Precision tiền theo `DEC-008` trong ADR 0003: `DECIMAL(19,4)`.

API sẽ dùng tên JSON trong `contracts/BASELINE.md`, chẳng hạn `MaSP` ↔ `maSanPham`, `MaViTri` ↔ `maViTri`. Các cột mã là chuỗi, không phải số tự tăng.

`SucChua` là số đơn vị tính gốc theo ADR 0004. Vị trí đang có tồn dương chỉ nhận lô cùng `MaDVT`; không cộng số lượng khác đơn vị để kết luận vị trí còn chỗ.
