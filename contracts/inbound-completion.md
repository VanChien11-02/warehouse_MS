# Contract dữ liệu nhập và tồn kho

- Status: Accepted for BE schema implementation; HTTP API/procedure pending
- Date: 2026-10-07
- Scope: INB-01, INV-01, BR-INB-001 đến BR-INB-007, BR-INV-001 đến BR-INV-005
- Owner triển khai: nhánh BE
- Reviewer tích hợp: repository owner và frontend owner

`PHIEU_NHAP` có mã `MaPN CHAR(6)`, nhà cung cấp, nhân viên lập, thời điểm tạo UTC, trạng thái `NHAP`/`DA_HOAN_THANH`/`DA_HUY`, ghi chú và thời điểm hoàn tất UTC. `NgayHoanTat` chỉ có giá trị khi trạng thái là `DA_HOAN_THANH`.

`CT_PHIEU_NHAP(MaPN, MaSP)` giữ số lượng nguyên dương và đơn giá nhập thực tế `DECIMAL(19,4)` không âm. `LO_HANG.MaLo` là mã lô; mỗi lô tham chiếu đúng một dòng `(MaPN, MaSP)`, có số lượng nhập nguyên dương, ngày sản xuất/hạn dùng tùy chọn và hạn không trước ngày sản xuất. Tổng lượng lô từ mỗi dòng không được vượt lượng dòng nhập; procedure hoàn tất sẽ kiểm tra trong transaction.

`TON_KHO(MaViTri, MaLo)` giữ tồn theo cặp vị trí/lô, số lượng nguyên không âm. Không lưu số tồn tổng trong sản phẩm. Sản phẩm và đơn vị tính của tồn được truy qua lô → dòng nhập → sản phẩm. Ứng dụng không ghi trực tiếp bảng tồn; các nghiệp vụ hoàn tất dùng procedure kiểm tra sức chứa, đơn vị tính và bảo quản trong cùng transaction.

`SEQ_PHIEU_NHAP` và `SEQ_LO_HANG` cấp số cho mã `PN0001` và `LO0001` theo ADR 0003. Khoảng trống sau rollback là hợp lệ; procedure phải trả lỗi rõ khi vượt không gian bốn chữ số.

API tạo/sửa/hủy nháp, payload phân bổ lô/vị trí, procedure hoàn tất và endpoint tra cứu tồn sẽ được chốt trong mốc kế tiếp. Chưa có endpoint ghi sổ hay tồn khả dụng trong commit schema này.
