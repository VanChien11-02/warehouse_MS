# Contract chuyển kho

- Status: Accepted for BE schema implementation; procedure/API pending
- Date: 2026-10-07
- Scope: TRF-01, BR-TRF-001 đến BR-TRF-005
- Owner triển khai: nhánh BE
- Reviewer tích hợp: repository owner và frontend owner

`PHIEU_CHUYEN_KHO.MaPCK CHAR(6)` là phiếu chuyển giữa hai vị trí. Header lưu nhân viên lập, thời điểm tạo UTC, ghi chú, trạng thái `NHAP`/`DA_HOAN_THANH`/`DA_HUY`, thời điểm hoàn tất UTC chỉ khi hoàn tất. `SEQ_PHIEU_CHUYEN_KHO` cấp mã `PC0001` theo quy tắc sequence ADR 0003; khoảng trống sau rollback là hợp lệ.

`CT_PHIEU_CHUYEN_KHO` có khóa `(MaPCK, MaLo, MaViTriNguon, MaViTriDich)` và số lượng nguyên dương. Nguồn và đích phải khác nhau; FK bảo đảm phiếu, lô và hai vị trí tồn tại. Một phiếu có thể có nhiều dòng/lô. Hoàn tất sẽ khóa phiếu, vị trí và tồn, kiểm tra tổng lượng theo từng cặp nguồn/lô, sức chứa và loại bảo quản tại đích rồi giảm nguồn/tăng đích trong cùng transaction. Sổ `BIEN_DONG_TON_KHO` ghi delta `CHUYEN` theo vị trí/lô để báo cáo từng kho phản ánh chuyển nội bộ.

API tạo/xem/sửa/hủy nháp và hoàn tất sẽ được chốt cùng procedure ở mốc tiếp theo. Chỉ `QuanLyKho` được hoàn tất theo ADR 0004.
