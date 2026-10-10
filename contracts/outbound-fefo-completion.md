# Contract dữ liệu xuất kho

- Status: Accepted for BE implementation (tạo nháp, xem chi tiết, hoàn tất); các route khác pending
- Date: 2026-10-07
- Scope: OUT-01, BR-OUT-001 đến BR-OUT-007
- Owner triển khai: nhánh BE
- Reviewer tích hợp: repository owner và frontend owner

`PHIEU_XUAT.MaPX CHAR(6)` định danh phiếu xuất. Header giữ đối tác nhận hàng `MaDTNH`, nhân viên lập `MaNV`, thời điểm tạo UTC, ghi chú, trạng thái `NHAP`/`DA_HOAN_THANH`/`DA_HUY` và thời điểm hoàn tất UTC. `NgayHoanTat` chỉ có khi hoàn tất. `SEQ_PHIEU_XUAT` cấp mã `PX0001` theo ADR 0003; khoảng trống sau rollback là hợp lệ.

`CT_PHIEU_XUAT(MaPX, MaLo, MaViTri)` giữ nguồn tồn cụ thể cho từng dòng. Số lượng nguyên dương, đơn giá xuất thực tế `DECIMAL(19,4)` không âm. Sản phẩm được suy ra từ `LO_HANG.MaSP`; không lưu thêm `MaSP` có thể mâu thuẫn. Dòng tham chiếu lô và vị trí, nhưng không FK tới `TON_KHO` vì sau khi xuất hết một cặp vị trí/lô, dòng tồn có thể về 0 hoặc bị xóa trong tương lai trong khi chứng từ phải giữ lịch sử.

`dbo.sp_HoanTatPhieuXuat(@MaPX CHAR(6), @NgayNghiepVu DATE)` khóa phiếu và các vị trí nguồn, kiểm tra cặp vị trí/lô có tồn đủ, lô chưa hết hạn theo ngày nghiệp vụ `Asia/Bangkok`, vị trí không phải `Hư hỏng`, đối tác được mapping với mọi sản phẩm, rồi trừ tồn và chuyển trạng thái trong cùng transaction. `@NgayNghiepVu` do backend tính; không được rỗng. Gợi ý FEFO chỉ là gợi ý; lúc hoàn tất phải khóa và kiểm tra lại theo [ADR 0005](../docs/architecture/adr/0005-outbound-fefo-enforcement.md). Lô không hạn đứng sau mọi lô còn hạn, lô hết hạn không được xuất. Thành công trả result set `maPhieuXuat`, `trangThai`, `ngayHoanTat` UTC.

Mã lỗi SQL ổn định: `51201` không thấy phiếu, `51202` trạng thái sai, `51203` thiếu ngày, `51204` thiếu dòng, `51205` vị trí không tồn tại, `51206` lô/vị trí không khả dụng, `51207` đối tác thiếu mapping, `51208` không đủ tồn, `51209` sai FEFO. JDBC adapter sẽ ánh xạ thành lỗi HTTP có cấu trúc, không trả message SQL thô.

HTTP API hiện có:

| Method | Route | Quyền | Kết quả |
| --- | --- | --- | --- |
| `GET` | `/api/phieu-xuat/{maPhieuXuat}` | Bốn role đã đăng nhập | `200` chi tiết phiếu và dòng |
| `POST` | `/api/phieu-xuat` | `QuanLyKho`, `NhanVienKho` + CSRF | `201` phiếu `NHAP`, `Location` |
| `POST` | `/api/phieu-xuat/{maPhieuXuat}/hoan-tat` | Chỉ `QuanLyKho` + CSRF | `200` mã, trạng thái và thời điểm hoàn tất |
| `GET` | `/api/phieu-xuat/{maPhieuXuat}/goi-y-fefo?maSanPham=SP0001&soLuong=5` | `QuanLyKho`, `NhanVienKho` | `200` phân bổ đề xuất |

Request tạo nháp:

```json
{"maDoiTacNhanHang":"DT0001","ghiChu":null,"chiTiet":[{"maLo":"LO0001","maViTri":"VT0001","soLuong":2,"donGiaXuat":20.0000}]}
```

Nhân viên lập lấy từ session, client không được gửi `maNhanVien`. Một cặp lô/vị trí chỉ có một dòng, số lượng nguyên dương, đơn giá không âm với tối đa bốn chữ số thập phân. Đối tác/lô/vị trí phải tồn tại; tồn đủ, FEFO, hạn dùng và mapping sản phẩm được kiểm tra lại lúc hoàn tất. Mã phiếu do server cấp. Response chi tiết thêm `ngayXuat`, `tenDoiTac`, `maNhanVien`, `trangThai`, `ngayHoanTat` và `chiTiet` có sản phẩm/hạn dùng. Thời điểm trả ISO-8601 UTC với `Z`.

Request hoàn tất không có body. Backend tính ngày nghiệp vụ `Asia/Bangkok` tại thời điểm gọi rồi truyền vào procedure; client không được chọn ngày để bỏ qua hạn dùng. Lỗi HTTP dùng envelope chung: `404 OUTBOUND_NOT_FOUND`; `409 OUTBOUND_NOT_DRAFT`, `INSUFFICIENT_STOCK`, `FEFO_VIOLATION`, `OUTBOUND_CODE_EXHAUSTED`; `422 LINES_REQUIRED`, `DUPLICATE_STOCK_SOURCE`, `INVALID_REFERENCE`, `INVALID_POSITION`, `STOCK_NOT_AVAILABLE`, `RECIPIENT_PRODUCT_NOT_LINKED`, `INVALID_CODE`, `VALIDATION_FAILED`; `401` chưa đăng nhập, `403` thiếu quyền/CSRF. Lỗi SQL không nhận diện trả `500 OUTBOUND_POSTING_FAILED` mà không lộ message SQL.

Gợi ý FEFO chỉ dùng được khi phiếu còn `NHAP`; `maSanPham` bắt buộc, `soLuong` nguyên dương, `maKho` tùy chọn để giới hạn nguồn. Response có `maPhieuXuat`, `maSanPham`, `soLuongYeuCau`, `soLuongThieu` và `phanBo` gồm `maLo`, `maViTri`, `soLuong`, `hanSuDung`. Khi tồn không đủ, API trả phần có thể phân bổ và số lượng còn thiếu; không giữ chỗ. Lô hết hạn và vị trí `Hư hỏng` không xuất hiện; lô không hạn đứng sau lô có hạn. `422 INVALID_QUANTITY` cho số lượng không dương.

Danh sách/lọc phiếu và sửa/hủy nháp sẽ được thêm trong mốc tiếp theo.
