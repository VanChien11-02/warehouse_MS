# Contract dữ liệu nhập và tồn kho

- Status: Accepted for BE implementation (tạo nháp, xem chi tiết, hoàn tất); các route khác pending
- Date: 2026-10-07
- Scope: INB-01, INV-01, BR-INB-001 đến BR-INB-007, BR-INV-001 đến BR-INV-005
- Owner triển khai: nhánh BE
- Reviewer tích hợp: repository owner và frontend owner

`PHIEU_NHAP` có mã `MaPN CHAR(6)`, nhà cung cấp, nhân viên lập, thời điểm tạo UTC, trạng thái `NHAP`/`DA_HOAN_THANH`/`DA_HUY`, ghi chú và thời điểm hoàn tất UTC. `NgayHoanTat` chỉ có giá trị khi trạng thái là `DA_HOAN_THANH`.

Mỗi lô/vị trí được tạo khi hoàn tất ghi một dòng `BIEN_DONG_TON_KHO` loại `NHAP`, delta dương và `NgayGhiSo` bằng `NgayHoanTat` của phiếu trong cùng transaction. Hoàn tất thất bại hoặc gọi lại không để lại biến động mới.

`CT_PHIEU_NHAP(MaPN, MaSP)` giữ số lượng nguyên dương và đơn giá nhập thực tế `DECIMAL(19,4)` không âm. `LO_HANG.MaLo` là mã lô; mỗi lô tham chiếu đúng một dòng `(MaPN, MaSP)`, có số lượng nhập nguyên dương, ngày sản xuất/hạn dùng tùy chọn và hạn không trước ngày sản xuất. Tổng lượng lô từ mỗi dòng không được vượt lượng dòng nhập, được trigger trên `LO_HANG` bảo vệ khi thêm/sửa lô. API chỉ sửa dòng của phiếu nháp chưa có lô, không sửa phiếu hoàn tất. Trigger chiều sửa dòng nhập đã được thay theo ADR 0009; không coi trigger trên lô là chốt chặn cho UPDATE trực tiếp bảng chi tiết.

`TON_KHO(MaViTri, MaLo)` giữ tồn theo cặp vị trí/lô, số lượng nguyên không âm. Không lưu số tồn tổng trong sản phẩm. Sản phẩm và đơn vị tính của tồn được truy qua lô → dòng nhập → sản phẩm. Ứng dụng không ghi trực tiếp bảng tồn; các nghiệp vụ hoàn tất dùng procedure kiểm tra sức chứa, đơn vị tính và bảo quản trong cùng transaction. Trigger trên `TON_KHO` chặn thêm/cập nhật làm vị trí vượt sức chứa hoặc trộn đơn vị tính; trigger trên sổ biến động chặn ghi sai chiều `NHAP`/`XUAT`/`TRA_HANG`.

`SEQ_PHIEU_NHAP` và `SEQ_LO_HANG` cấp số cho mã `PN0001` và `LO0001` theo ADR 0003. Khoảng trống sau rollback là hợp lệ; procedure phải trả lỗi rõ khi vượt không gian bốn chữ số.

`dbo.sp_HoanTatPhieuNhap(@MaPN CHAR(6), @PhanBoJson NVARCHAR(MAX), @MaTK CHAR(6) = NULL)` là điểm ghi sổ nhập. API truyền tài khoản hiện tại để ghi audit cùng transaction; lời gọi SQL trực tiếp có thể bỏ `@MaTK`. JSON là array, mỗi phần tử tạo một lô mới:

```json
[{"maSanPham":"SP0001","maViTri":"VT0001","soLuong":10,"ngaySanXuat":"2026-01-01","hanSuDung":"2026-12-31"}]
```

Ngày có thể `null` hoặc bỏ qua. Tổng `soLuong` của các phần tử theo từng `maSanPham` phải **bằng** lượng trên `CT_PHIEU_NHAP` để một phiếu hoàn tất không bỏ sót hàng. Procedure khóa phiếu và vị trí nhận, kiểm tra mapping nhà cung cấp/sản phẩm, ngày lô, loại bảo quản, một đơn vị tính cho mỗi vị trí có tồn dương và sức chứa trước khi tạo lô/tăng tồn. Phiếu phải ở `NHAP`; hoàn tất lặp trả lỗi mà không ghi thêm. Thành công trả result set `maPhieuNhap`, `trangThai`, `ngayHoanTat` UTC.

Theo [ADR 0008](../docs/architecture/adr/0008-inbound-integrity-boundary.md),
procedure chặn tổng phân bổ **thiếu**; trigger chặn tổng lô **vượt** dòng nhập
khi INSERT lô trong chính transaction hoàn tất. UI nhập thật hiển thị lỗi và
giữ phiếu nháp để sửa. Theo [ADR 0009](../docs/architecture/adr/0009-category-storage-history-guard.md),
trigger dòng nhập cũ đã được thay bằng guard bảo quản của loại sản phẩm; vẫn
không cho sửa phiếu hoàn tất.

Mã lỗi SQL ổn định trong dải `51101–51113`: `51101` không thấy phiếu; `51102` trạng thái sai; `51103–51104` JSON/dữ liệu phân bổ sai; `51105` thiếu dòng; `51106` thiếu mapping; `51107` sản phẩm không thuộc phiếu; `51108` phân bổ thiếu; `51109` vị trí không tồn tại; `51110` bảo quản hoặc loại vị trí sai; `51111` trộn đơn vị; `51112` vượt sức chứa; `51113` hết mã lô. Tổng lô vượt dòng do trigger phát `51820`, không kiểm tra trùng điều kiện này trước INSERT lô. JDBC adapter ánh xạ 51820 thành HTTP 422 `ALLOCATION_EXCEEDS_LINE`, 51108 thành 422 `ALLOCATION_INCOMPLETE`; không trả message SQL thô. Lỗi trigger rollback cả nghiệp vụ giống các lỗi procedure.

HTTP API hiện có:

Refactor 2026-10-25 (migration 031) giữ nguyên contract này: chuyển đổi ngày
một lần, gộp kiểm tra đơn vị của hàng mới và tồn cũ, giữ vòng lặp tạo từng lô.
Năm bước cùng lời giải thích transaction tại
[`../docs/development/INBOUND_WALKTHROUGH.md`](../docs/development/INBOUND_WALKTHROUGH.md).

| Method | Route | Quyền | Kết quả |
| --- | --- | --- | --- |
| `GET` | `/api/phieu-nhap/{maPhieuNhap}` | `QuanLyKho`, `NhanVienKho`, `KeToan` | `200` chi tiết phiếu và dòng |
| `GET` | `/api/phieu-nhap?trangThai=NHAP&maNhaCungCap=NCC001&page=0&size=20` | `QuanLyKho`, `NhanVienKho`, `KeToan` | `200` danh sách header phân trang |
| `GET` | `/api/phieu-nhap/lich-su` | `QuanLyKho`, `KeToan` | `200` lịch sử theo lô, đọc trực tiếp `dbo.vw_LichSuNhapKho` |
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

Lỗi HTTP dùng envelope chung: `404 INBOUND_NOT_FOUND`; `409 INBOUND_NOT_DRAFT`, `CAPACITY_EXCEEDED`, `UNIT_MISMATCH`, `LOT_CODE_EXHAUSTED`, `INBOUND_CODE_EXHAUSTED`; `422 LINES_REQUIRED`, `DUPLICATE_PRODUCT`, `ALLOCATIONS_REQUIRED`, `INVALID_ALLOCATION`, `ALLOCATION_INCOMPLETE`, `ALLOCATION_EXCEEDS_LINE`, `SUPPLIER_PRODUCT_NOT_LINKED`, `INVALID_POSITION`, `INCOMPATIBLE_STORAGE`, `INVALID_REFERENCE`, `INVALID_CODE`, `INVALID_STATUS`, `INVALID_PAGINATION`, `VALIDATION_FAILED`; `401` chưa đăng nhập, `403` thiếu quyền/CSRF. Lỗi SQL ngoài danh sách trả `500 INBOUND_POSTING_FAILED` mà không lộ message SQL.

Tra cứu tồn theo lô/vị trí có contract riêng tại [`inventory-query.md`](inventory-query.md).

## Lịch sử nhập kho theo lô

`GET /api/phieu-nhap/lich-su?page=0&size=20&maPhieuNhap=PN0001` truy vấn trực
tiếp `dbo.vw_LichSuNhapKho`, không dựng lại các JOIN hoặc trạng thái tại Java.
Không thay schema/view, vì view đã có từ migration 023 và `init.sql`. Không
cần migration mới. Quyền đọc khớp GRANT hiện hành của view cho manager/accountant;
NVKHO và ADMIN nhận 403, chưa đăng nhập nhận 401.

Filter tùy chọn: `maPhieuNhap`, `maSanPham`, `maNhaCungCap` là mã chính xác,
trim/uppercase; rỗng coi như không lọc. `tuNgay`, `denNgay` định dạng ISO
`yyyy-MM-dd`, lọc **ngày hoàn tất UTC**, gồm cả hai mốc. Từ ngày sau đến ngày
trả 422 `INVALID_DATE_RANGE`; mã sai trả 422 `INVALID_CODE`; page/size sai trả
422 `INVALID_PAGINATION`; ngày hoặc số không đọc được trả 400 `INVALID_PARAMETER`.
`page` 0–1.000.000, `size` 1–100, mặc định 0/20.

Response `{items,page,size,totalElements,totalPages}`. Mỗi item có
`maPhieuNhap`, `ngayHoanTat` UTC, `maNhaCungCap`, `maSanPham`, `tenSanPham`,
`maDonViTinh`, `maLo`, `ngaySanXuat`, `hanSuDung`, `soLuongNhap`, `donGiaNhap`,
`giaTriNhap`. Ngày lô có thể null; tiền lấy DECIMAL từ view, Java dùng
BigDecimal. Sắp `ngayHoanTat DESC, maPhieuNhap DESC, maLo ASC`. Không có dữ
liệu trả 200/items rỗng. Tổng dòng là **số lô**, không phải số phiếu.

UI API tại **Phiếu nhập kho → Lịch sử nhập kho**, có bộ lọc, phân trang,
loading/empty/error/retry; bấm mã phiếu mở chứng từ gốc. Lưu nháp hoặc ghi sổ
rollback không tạo lịch sử; hoàn tất 6+4 tạo hai dòng giá trị 75.000 và 50.000
nếu đơn giá 12.500. Đây là lượng/giá trị nhập ban đầu, không phải tồn hiện tại;
lô đã xuất hết vẫn thuộc lịch sử. Chuyển tab giữ nội dung nháp đang nhập.
