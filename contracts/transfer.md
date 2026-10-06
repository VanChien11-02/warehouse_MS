# Contract chuyển kho

- Status: Accepted for BE schema, procedure and core API implementation
- Date: 2026-10-07
- Scope: TRF-01, BR-TRF-001 đến BR-TRF-005
- Owner triển khai: nhánh BE
- Reviewer tích hợp: repository owner và frontend owner

`PHIEU_CHUYEN_KHO.MaPCK CHAR(6)` là phiếu chuyển giữa hai vị trí. Header lưu nhân viên lập, thời điểm tạo UTC, ghi chú, trạng thái `NHAP`/`DA_HOAN_THANH`/`DA_HUY`, thời điểm hoàn tất UTC chỉ khi hoàn tất. `SEQ_PHIEU_CHUYEN_KHO` cấp mã `PC0001` theo quy tắc sequence ADR 0003; khoảng trống sau rollback là hợp lệ.

`CT_PHIEU_CHUYEN_KHO` có khóa `(MaPCK, MaLo, MaViTriNguon, MaViTriDich)` và số lượng nguyên dương. Nguồn và đích phải khác nhau; FK bảo đảm phiếu, lô và hai vị trí tồn tại. Một phiếu có thể có nhiều dòng/lô. `dbo.sp_HoanTatChuyenKho(@MaPCK CHAR(6))` khóa phiếu, vị trí và tồn, kiểm tra tổng lượng theo từng cặp nguồn/lô, sức chứa sau chuyển, một đơn vị tính ở mỗi vị trí còn tồn dương và loại bảo quản tại đích, rồi cập nhật tồn trong cùng transaction. Vị trí `Hư hỏng` không tham gia chuyển thường theo [ADR 0006](../docs/architecture/adr/0006-transfer-posting.md).

Sổ `BIEN_DONG_TON_KHO` ghi delta `CHUYEN` ròng theo vị trí/lô trong cùng transaction. Phiếu hoàn tất lặp trả lỗi mà không ghi thêm; lỗi tại bước ghi sổ sau cập nhật tồn vẫn rollback nguồn/đích. Thành công trả result set `maPhieuChuyen`, `trangThai`, `ngayHoanTat` UTC. Mã lỗi SQL ổn định: `51301` không thấy phiếu, `51302` trạng thái sai, `51303` thiếu dòng, `51304` vị trí không tồn tại, `51305` vị trí/bảo quản không phù hợp, `51306` thiếu tồn nguồn, `51307` vượt sức chứa, `51308` trộn đơn vị tính.

HTTP API dùng session/CSRF chung:

| Method | Route | Quyền | Kết quả |
| --- | --- | --- | --- |
| `POST` | `/api/phieu-chuyen` | `QuanLyKho`, `NhanVienKho` + CSRF | `201` phiếu `NHAP`, `Location` |
| `GET` | `/api/phieu-chuyen/{maPhieuChuyen}` | Bốn role đã đăng nhập | `200` header và dòng |
| `POST` | `/api/phieu-chuyen/{maPhieuChuyen}/hoan-tat` | Chỉ `QuanLyKho` + CSRF | `200` mã, trạng thái và thời điểm hoàn tất |

Tạo nháp: `{"ghiChu":null,"chiTiet":[{"maLo":"LO0001","maViTriNguon":"VT0001","maViTriDich":"VT0002","soLuong":2}]}`. Nhân viên lấy từ session, mã phiếu do server cấp. Một cặp lô/nguồn/đích chỉ có một dòng; số lượng nguyên dương. Response chi tiết thêm `ngayChuyen`, `maNhanVien`, `trangThai`, `ngayHoanTat`, tên/mã sản phẩm từng dòng. Thời điểm trả ISO-8601 UTC với `Z`.

Lỗi HTTP: `404 TRANSFER_NOT_FOUND`; `409 TRANSFER_NOT_DRAFT`, `TRANSFER_CODE_EXHAUSTED`, `INSUFFICIENT_STOCK`, `CAPACITY_EXCEEDED`, `UNIT_MISMATCH`; `422 LINES_REQUIRED`, `SAME_POSITION`, `INVALID_QUANTITY`, `DUPLICATE_TRANSFER_LINE`, `INVALID_REFERENCE`, `INVALID_POSITION`, `INCOMPATIBLE_STORAGE`, `INVALID_CODE`, `VALIDATION_FAILED`; `401` chưa đăng nhập, `403` sai quyền/CSRF. Lỗi SQL không nhận diện trả `500 TRANSFER_POSTING_FAILED` mà không lộ message SQL.

Danh sách/sửa/hủy nháp sẽ được bổ sung ở mốc tiếp theo.
