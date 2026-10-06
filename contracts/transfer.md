# Contract chuyển kho

- Status: Accepted for BE schema and procedure implementation; API pending
- Date: 2026-10-07
- Scope: TRF-01, BR-TRF-001 đến BR-TRF-005
- Owner triển khai: nhánh BE
- Reviewer tích hợp: repository owner và frontend owner

`PHIEU_CHUYEN_KHO.MaPCK CHAR(6)` là phiếu chuyển giữa hai vị trí. Header lưu nhân viên lập, thời điểm tạo UTC, ghi chú, trạng thái `NHAP`/`DA_HOAN_THANH`/`DA_HUY`, thời điểm hoàn tất UTC chỉ khi hoàn tất. `SEQ_PHIEU_CHUYEN_KHO` cấp mã `PC0001` theo quy tắc sequence ADR 0003; khoảng trống sau rollback là hợp lệ.

`CT_PHIEU_CHUYEN_KHO` có khóa `(MaPCK, MaLo, MaViTriNguon, MaViTriDich)` và số lượng nguyên dương. Nguồn và đích phải khác nhau; FK bảo đảm phiếu, lô và hai vị trí tồn tại. Một phiếu có thể có nhiều dòng/lô. `dbo.sp_HoanTatChuyenKho(@MaPCK CHAR(6))` khóa phiếu, vị trí và tồn, kiểm tra tổng lượng theo từng cặp nguồn/lô, sức chứa sau chuyển, một đơn vị tính ở mỗi vị trí còn tồn dương và loại bảo quản tại đích, rồi cập nhật tồn trong cùng transaction. Vị trí `Hư hỏng` không tham gia chuyển thường theo [ADR 0006](../docs/architecture/adr/0006-transfer-posting.md).

Sổ `BIEN_DONG_TON_KHO` ghi delta `CHUYEN` ròng theo vị trí/lô trong cùng transaction. Phiếu hoàn tất lặp trả lỗi mà không ghi thêm; lỗi tại bước ghi sổ sau cập nhật tồn vẫn rollback nguồn/đích. Thành công trả result set `maPhieuChuyen`, `trangThai`, `ngayHoanTat` UTC. Mã lỗi SQL ổn định: `51301` không thấy phiếu, `51302` trạng thái sai, `51303` thiếu dòng, `51304` vị trí không tồn tại, `51305` vị trí/bảo quản không phù hợp, `51306` thiếu tồn nguồn, `51307` vượt sức chứa, `51308` trộn đơn vị tính.

API tạo/xem/sửa/hủy nháp và hoàn tất sẽ được chốt trong mốc tiếp theo. Chỉ `QuanLyKho` được hoàn tất theo ADR 0004.
