# Physical schema: identity, danh mục và cấu trúc kho

Trạng thái: phần đầu của DB-01. Tài liệu này mô tả 17 bảng đã có trong `database/schema/`; các bảng chứng từ xuất và kiểm soát kho còn lại chưa được triển khai.

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
| `NHA_CUNG_CAP` | `MaNCC CHAR(6)` | — | Tên bắt buộc; địa chỉ, điện thoại và email tùy chọn |
| `DOI_TAC_NHAN_HANG` | `MaDTNH CHAR(6)` | — | Tên và loại đối tác bắt buộc; thông tin liên hệ tùy chọn |
| `NHA_CUNG_CAP_SAN_PHAM` | `(MaNCC, MaSP)` | `MaNCC`, `MaSP` | Một nhà cung cấp chỉ mapping một lần với một sản phẩm |
| `DOI_TAC_SAN_PHAM` | `(MaDTNH, MaSP)` | `MaDTNH`, `MaSP` | Đối tác nhận hàng tham chiếu đúng `DOI_TAC_NHAN_HANG` |
| `PHIEU_NHAP` | `MaPN CHAR(6)` | `MaNCC`, `MaNV` | Trạng thái nháp/hoàn tất/hủy; `NgayHoanTat` chỉ có khi hoàn tất; thời điểm UTC |
| `CT_PHIEU_NHAP` | `(MaPN, MaSP)` | `MaPN`, `MaSP` | Số lượng nguyên dương; `DonGiaNhap DECIMAL(19,4)` không âm |
| `LO_HANG` | `MaLo CHAR(6)` | `(MaPN, MaSP)` | Số lượng nhập dương; hạn dùng không trước ngày sản xuất |
| `TON_KHO` | `(MaViTri, MaLo)` | `MaViTri`, `MaLo` | Số lượng tồn không âm, theo đúng cặp vị trí/lô |

Tên và mô tả dùng `NVARCHAR` để lưu tiếng Việt; mã dùng `CHAR(6)` theo tài liệu nguồn. `MoTa` dùng `NVARCHAR(1000)` thay cho kiểu `TEXT` cũ. Giá mặc định bằng 0 khi không cung cấp, nhưng giá nhập/xuất thực tế nằm trên dòng chứng từ.

Precision tiền theo `DEC-008` trong ADR 0003: `DECIMAL(19,4)`.

API sẽ dùng tên JSON trong `contracts/BASELINE.md`, chẳng hạn `MaSP` ↔ `maSanPham`, `MaViTri` ↔ `maViTri`. Các cột mã là chuỗi, không phải số tự tăng.

Identity map `TAI_KHOAN.MaTK` ↔ `maTaiKhoan`, `NHAN_VIEN.MaNV` ↔ `maNhanVien`, `TAI_KHOAN.TenTK` ↔ `tenTaiKhoan`, `ROLE.MaRole` ↔ `role` theo `contracts/session-rbac.md`. `MatKhauHash` không có trường response công khai.

`SucChua` là số đơn vị tính gốc theo ADR 0004. Vị trí đang có tồn dương chỉ nhận lô cùng `MaDVT`; không cộng số lượng khác đơn vị để kết luận vị trí còn chỗ.

Mapping đối tác/sản phẩm phục vụ kiểm tra khi hoàn tất nhập/xuất theo [`contracts/partner.md`](../../../contracts/partner.md); tạo nháp không ghi sổ tồn.

`SEQ_PHIEU_NHAP` và `SEQ_LO_HANG` cấp số mã chứng từ/lô. Quy tắc tổng số lượng lô, sức chứa, đơn vị tính và bảo quản cần procedure hoàn tất kiểm tra trong transaction theo [`contracts/inbound-completion.md`](../../../contracts/inbound-completion.md).

`sp_HoanTatPhieuNhap` đã có `TRY...CATCH`, transaction, khóa phiếu/vị trí, kiểm tra mapping và số lượng phân bổ, tạo lô/tồn rồi chuyển trạng thái một lần. API tạo/xem/hoàn tất nhập và tra cứu tồn đã có; danh sách/sửa/hủy nháp chưa có.
`vw_TonKhoChiTiet` nối tồn với vị trí, sản phẩm, phiếu nhập, lô và giá nhập thực tế; chỉ lấy phiếu `DA_HOAN_THANH`. View phục vụ [`contracts/inventory-query.md`](../../../contracts/inventory-query.md) và báo cáo sau này.
