# Physical schema: identity, danh mục và cấu trúc kho

Trạng thái: phần đầu của DB-01. Tài liệu này mô tả 26 bảng đã có trong `database/schema/`; procedure nhập/xuất/chuyển/kiểm kê đã có, procedure trả và audit chưa triển khai.

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
| `PHIEU_XUAT` | `MaPX CHAR(6)` | `MaDTNH`, `MaNV` | Trạng thái nháp/hoàn tất/hủy; `NgayHoanTat` chỉ có khi hoàn tất; thời điểm UTC |
| `CT_PHIEU_XUAT` | `(MaPX, MaLo, MaViTri)` | `MaPX`, `MaLo`, `MaViTri` | Dòng chỉ rõ nguồn tồn, số lượng dương, `DonGiaXuat DECIMAL(19,4)` không âm |
| `BIEN_DONG_TON_KHO` | `MaBienDong BIGINT IDENTITY` | `MaViTri`, `MaLo` | Mỗi cặp nghiệp vụ/chứng từ/vị trí/lô xuất hiện một lần; delta khác 0; thời điểm UTC |
| `PHIEU_CHUYEN_KHO` | `MaPCK CHAR(6)` | `MaNV` | Trạng thái nháp/hoàn tất/hủy; thời điểm UTC, hoàn tất phải có `NgayHoanTat` |
| `CT_PHIEU_CHUYEN_KHO` | `(MaPCK, MaLo, MaViTriNguon, MaViTriDich)` | `MaPCK`, `MaLo`, hai vị trí | Số lượng nguyên dương; nguồn khác đích |
| `PHIEU_KIEM_KE` | `MaPKK CHAR(6)` | `MaNV`, `MaViTri` | Trạng thái nháp/hoàn tất/hủy; thời điểm UTC, hoàn tất phải có `NgayHoanTat` |
| `CT_KIEM_KE` | `(MaPKK, MaLo)` | `MaPKK`, `MaLo` | Lưu số tồn hệ thống tại lúc tạo snapshot và số đếm thực tế không âm; lý do chênh lệch kiểm tra khi hoàn tất |
| `PHIEU_TRA_HANG` | `MaPTH CHAR(6)` | `MaPX`, `MaNV` | Tham chiếu phiếu xuất gốc; trạng thái nháp/hoàn tất/hủy; thời điểm UTC |
| `CT_PHIEU_TRA_HANG` | `(MaPTH, MaLo)` | `MaPTH`, `MaLo`, `MaViTri` | Số lượng dương; tình trạng `Tốt`/`Hư hỏng`; đích lưu trữ cụ thể |

Tên và mô tả dùng `NVARCHAR` để lưu tiếng Việt; mã dùng `CHAR(6)` theo tài liệu nguồn. `MoTa` dùng `NVARCHAR(1000)` thay cho kiểu `TEXT` cũ. Giá mặc định bằng 0 khi không cung cấp, nhưng giá nhập/xuất thực tế nằm trên dòng chứng từ.

Precision tiền theo `DEC-008` trong ADR 0003: `DECIMAL(19,4)`.

API sẽ dùng tên JSON trong `contracts/BASELINE.md`, chẳng hạn `MaSP` ↔ `maSanPham`, `MaViTri` ↔ `maViTri`. Các cột mã là chuỗi, không phải số tự tăng.

Identity map `TAI_KHOAN.MaTK` ↔ `maTaiKhoan`, `NHAN_VIEN.MaNV` ↔ `maNhanVien`, `TAI_KHOAN.TenTK` ↔ `tenTaiKhoan`, `ROLE.MaRole` ↔ `role` theo `contracts/session-rbac.md`. `MatKhauHash` không có trường response công khai.

`SucChua` là số đơn vị tính gốc theo ADR 0004. Vị trí đang có tồn dương chỉ nhận lô cùng `MaDVT`; không cộng số lượng khác đơn vị để kết luận vị trí còn chỗ.

Mapping đối tác/sản phẩm phục vụ kiểm tra khi hoàn tất nhập/xuất theo [`contracts/partner.md`](../../../contracts/partner.md); tạo nháp không ghi sổ tồn.

`SEQ_PHIEU_NHAP` và `SEQ_LO_HANG` cấp số mã chứng từ/lô. Quy tắc tổng số lượng lô, sức chứa, đơn vị tính và bảo quản cần procedure hoàn tất kiểm tra trong transaction theo [`contracts/inbound-completion.md`](../../../contracts/inbound-completion.md).

`sp_HoanTatPhieuNhap` đã có `TRY...CATCH`, transaction, khóa phiếu/vị trí, kiểm tra mapping và số lượng phân bổ, tạo lô/tồn rồi chuyển trạng thái một lần. API danh sách/tạo/sửa/hủy nháp/xem/hoàn tất nhập và tra cứu tồn đã có.
`vw_TonKhoChiTiet` nối tồn với vị trí, sản phẩm, phiếu nhập, lô và giá nhập thực tế; chỉ lấy phiếu `DA_HOAN_THANH`. View phục vụ [`contracts/inventory-query.md`](../../../contracts/inventory-query.md) và báo cáo sau này.

`SEQ_PHIEU_XUAT` cấp mã `PX0001`; `sp_HoanTatPhieuXuat` kiểm tra FEFO, khóa tồn và mapping đối tác theo [`contracts/outbound-fefo-completion.md`](../../../contracts/outbound-fefo-completion.md).

`BIEN_DONG_TON_KHO` là sổ biến động ghi cùng transaction hoàn tất nhập/xuất. Mỗi dòng giữ loại nghiệp vụ, mã chứng từ, vị trí, lô, lượng tăng/giảm và thời điểm ghi sổ UTC. Unique key ngăn lặp cùng nghiệp vụ/chứng từ/vị trí/lô; index `IX_BIEN_DONG_TON_KHO_NGAY` phục vụ lọc khoảng ngày báo cáo. Migration 007 chỉ dựng sổ từ dữ liệu lịch sử khi mỗi lô còn đúng một vị trí và tổng biến động khớp tồn hiện có; dữ liệu lệch dừng migration để đối chiếu thủ công. Các nghiệp vụ chuyển/kiểm kê/trả sẽ bổ sung dòng sổ theo contract của chúng.

`vw_BienDongTonKhoChiTiet` nối sổ biến động với kho, sản phẩm và giá nhập thực tế của lô. View là nguồn cho [`contracts/reporting.md`](../../../contracts/reporting.md); test SQL xác nhận giá trị nhập/xuất và số dư sau ghi sổ.

`SEQ_PHIEU_CHUYEN_KHO` cấp mã `PC0001`; `sp_HoanTatChuyenKho` kiểm tra tồn nguồn, sức chứa/đơn vị/bảo quản ở đích và ghi biến động hai phía theo [`contracts/transfer.md`](../../../contracts/transfer.md). API chuyển kho chưa có ở mốc procedure.

`SEQ_PHIEU_KIEM_KE` cấp mã `KK0001`. Phiếu gắn một vị trí; dòng `(MaPKK, MaLo)` giữ số tồn hệ thống bất biến sau khi tạo và số đếm thực tế có thể để trống trong nháp. Quy tắc lý do chênh lệch và đối chiếu snapshot được ghi trong [`contracts/inventory-count.md`](../../../contracts/inventory-count.md).

`sp_HoanTatKiemKe` khóa phiếu, vị trí và tồn; so snapshot với lượng hiện tại, kiểm tra lý do, sức chứa, đơn vị và bảo quản rồi điều chỉnh tồn cùng dòng sổ `KIEM_KE` trong một transaction. Procedure từ chối chốt lặp; test cố ý gây lỗi ghi sổ muộn để xác nhận tồn và trạng thái rollback.

`vw_ChenhLechKiemKe` chỉ gồm các dòng có chênh lệch khác 0 của phiếu đã hoàn tất, giữ nguyên số hệ thống lúc snapshot và nối đến kho/lô/sản phẩm để báo cáo theo kỳ tại [`contracts/count-discrepancy-report.md`](../../../contracts/count-discrepancy-report.md).

`SEQ_PHIEU_TRA_HANG` cấp mã `TH0001`; phiếu trả gắn phiếu xuất và mỗi dòng gắn lô/vị trí đích, theo [`contracts/returning.md`](../../../contracts/returning.md).
