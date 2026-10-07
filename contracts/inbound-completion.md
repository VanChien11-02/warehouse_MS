# Contract dữ liệu nhập và tồn kho

- Status: Accepted for BE implementation (tạo nháp, xem chi tiết, hoàn tất); các route khác pending
- Date: 2026-10-07
- Scope: INB-01, INV-01, BR-INB-001 đến BR-INB-007, BR-INV-001 đến BR-INV-005
- Owner triển khai: nhánh BE
- Reviewer tích hợp: repository owner và frontend owner

`PHIEU_NHAP` có mã `MaPN CHAR(6)`, nhà cung cấp, nhân viên lập, thời điểm tạo UTC, trạng thái `NHAP`/`DA_HOAN_THANH`/`DA_HUY`, ghi chú và thời điểm hoàn tất UTC. `NgayHoanTat` chỉ có giá trị khi trạng thái là `DA_HOAN_THANH`.

Mỗi lô/vị trí được tạo khi hoàn tất ghi một dòng `BIEN_DONG_TON_KHO` loại `NHAP`, delta dương và `NgayGhiSo` bằng `NgayHoanTat` của phiếu trong cùng transaction. Hoàn tất thất bại hoặc gọi lại không để lại biến động mới.

`CT_PHIEU_NHAP(MaPN, MaSP)` giữ số lượng nguyên dương và đơn giá nhập thực tế `DECIMAL(19,4)` không âm. `LO_HANG.MaLo` là mã lô; mỗi lô tham chiếu đúng một dòng `(MaPN, MaSP)`, có số lượng nhập nguyên dương, ngày sản xuất/hạn dùng tùy chọn và hạn không trước ngày sản xuất. Tổng lượng lô từ mỗi dòng không được vượt lượng dòng nhập; procedure hoàn tất sẽ kiểm tra trong transaction.

`TON_KHO(MaViTri, MaLo)` giữ tồn theo cặp vị trí/lô, số lượng nguyên không âm. Không lưu số tồn tổng trong sản phẩm. Sản phẩm và đơn vị tính của tồn được truy qua lô → dòng nhập → sản phẩm. Ứng dụng không ghi trực tiếp bảng tồn; các nghiệp vụ hoàn tất dùng procedure kiểm tra sức chứa, đơn vị tính và bảo quản trong cùng transaction.

`SEQ_PHIEU_NHAP` và `SEQ_LO_HANG` cấp số cho mã `PN0001` và `LO0001` theo ADR 0003. Khoảng trống sau rollback là hợp lệ; procedure phải trả lỗi rõ khi vượt không gian bốn chữ số.

`dbo.sp_HoanTatPhieuNhap(@MaPN CHAR(6), @PhanBoJson NVARCHAR(MAX), @MaTK CHAR(6) = NULL)` là điểm ghi sổ nhập. API truyền tài khoản hiện tại để ghi audit cùng transaction; lời gọi SQL trực tiếp có thể bỏ `@MaTK`. JSON là array, mỗi phần tử tạo một lô mới:

```json
[{"maSanPham":"SP0001","maViTri":"VT0001","soLuong":10,"ngaySanXuat":"2026-01-01","hanSuDung":"2026-12-31"}]
```

Ngày có thể `null` hoặc bỏ qua. Tổng `soLuong` của các phần tử theo từng `maSanPham` phải **bằng** lượng trên `CT_PHIEU_NHAP` để một phiếu hoàn tất không bỏ sót hàng. Procedure khóa phiếu và vị trí nhận, kiểm tra mapping nhà cung cấp/sản phẩm, ngày lô, loại bảo quản, một đơn vị tính cho mỗi vị trí có tồn dương và sức chứa trước khi tạo lô/tăng tồn. Phiếu phải ở `NHAP`; hoàn tất lặp trả lỗi mà không ghi thêm. Thành công trả result set `maPhieuNhap`, `trangThai`, `ngayHoanTat` UTC.

Mã lỗi SQL ổn định trong dải `51101–51113`: `51101` không thấy phiếu; `51102` trạng thái sai; `51103–51104` JSON/dữ liệu phân bổ sai; `51105` thiếu dòng; `51106` thiếu mapping; `51107–51108` sản phẩm/số lượng không khớp; `51109` vị trí không tồn tại; `51110` bảo quản hoặc loại vị trí sai; `51111` trộn đơn vị; `51112` vượt sức chứa; `51113` hết mã lô. JDBC adapter sẽ ánh xạ các số này sang mã HTTP contract, không trả message SQL thô.

HTTP API hiện có:

| Method | Route | Quyền | Kết quả |
| --- | --- | --- | --- |
| `GET` | `/api/phieu-nhap/{maPhieuNhap}` | Bốn role đã đăng nhập | `200` chi tiết phiếu và dòng |
| `GET` | `/api/phieu-nhap?trangThai=NHAP&maNhaCungCap=NCC001&page=0&size=20` | Bốn role đã đăng nhập | `200` danh sách header phân trang |
| `POST` | `/api/phieu-nhap` | `QuanLyKho`, `NhanVienKho` + CSRF | `201` phiếu `NHAP`, `Location` |
| `PUT` | `/api/phieu-nhap/{maPhieuNhap}` | `QuanLyKho`, `NhanVienKho` + CSRF | `200` phiếu nháp sau khi thay toàn bộ header/dòng |
| `POST` | `/api/phieu-nhap/{maPhieuNhap}/huy` | `QuanLyKho`, `NhanVienKho` + CSRF | `200` phiếu `DA_HUY`, giữ lại chứng từ và dòng |
| `POST` | `/api/phieu-nhap/{maPhieuNhap}/hoan-tat` | Chỉ `QuanLyKho` + CSRF | `200` mã, trạng thái và thời điểm hoàn tất |

Request tạo nháp:

```json
{"maNhaCungCap":"NCC001","ghiChu":null,"chiTiet":[{"maSanPham":"SP0001","soLuong":10,"donGiaNhap":12.3400}]}
```

Nhân viên lập lấy từ session, client không được gửi `maNhanVien`. Mỗi sản phẩm chỉ có một dòng; số lượng nguyên dương, đơn giá không âm với tối đa bốn chữ số thập phân. Nhà cung cấp/sản phẩm phải tồn tại, nhưng mapping được kiểm tra lại lúc hoàn tất. Mã phiếu do server cấp. Response chi tiết thêm `ngayNhap`, `tenNhaCungCap`, `maNhanVien`, `trangThai`, `ngayHoanTat` và `chiTiet` có `tenSanPham`. Thời điểm trả ISO-8601 UTC với `Z`.

`PUT` dùng cùng body như `POST` tạo nháp và thay toàn bộ dòng trong một transaction sau khi khóa header `NHAP`. `huy` khóa header và chỉ chuyển `NHAP` → `DA_HUY`, không xóa vật lý. Phiếu hoàn tất/đã hủy trả `409 INBOUND_NOT_DRAFT` cho cả sửa và hủy. Danh sách lọc tùy chọn trạng thái thuộc `NHAP`, `DA_HOAN_THANH`, `DA_HUY` và mã nhà cung cấp; `size` 1–100, `page` bắt đầu 0; response `{items,page,size,totalElements,totalPages}` với item chỉ có header, xếp `ngayNhap` mới nhất trước.

Request hoàn tất:

```json
{"phanBo":[{"maSanPham":"SP0001","maViTri":"VT0001","soLuong":10,"ngaySanXuat":"2026-01-01","hanSuDung":"2026-12-31"}]}
```

Lỗi HTTP dùng envelope chung: `404 INBOUND_NOT_FOUND`; `409 INBOUND_NOT_DRAFT`, `CAPACITY_EXCEEDED`, `UNIT_MISMATCH`, `LOT_CODE_EXHAUSTED`, `INBOUND_CODE_EXHAUSTED`; `422 LINES_REQUIRED`, `DUPLICATE_PRODUCT`, `ALLOCATIONS_REQUIRED`, `INVALID_ALLOCATION`, `SUPPLIER_PRODUCT_NOT_LINKED`, `INVALID_POSITION`, `INCOMPATIBLE_STORAGE`, `INVALID_REFERENCE`, `INVALID_CODE`, `INVALID_STATUS`, `INVALID_PAGINATION`, `VALIDATION_FAILED`; `401` chưa đăng nhập, `403` thiếu quyền/CSRF. Lỗi SQL ngoài danh sách trả `500 INBOUND_POSTING_FAILED` mà không lộ message SQL.

Tra cứu tồn theo lô/vị trí có contract riêng tại [`inventory-query.md`](inventory-query.md).
