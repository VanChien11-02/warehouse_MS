# Contract dữ liệu xuất kho

- Status: Accepted for BE schema implementation; procedure/HTTP API pending
- Date: 2026-10-07
- Scope: OUT-01, BR-OUT-001 đến BR-OUT-007
- Owner triển khai: nhánh BE
- Reviewer tích hợp: repository owner và frontend owner

`PHIEU_XUAT.MaPX CHAR(6)` định danh phiếu xuất. Header giữ đối tác nhận hàng `MaDTNH`, nhân viên lập `MaNV`, thời điểm tạo UTC, ghi chú, trạng thái `NHAP`/`DA_HOAN_THANH`/`DA_HUY` và thời điểm hoàn tất UTC. `NgayHoanTat` chỉ có khi hoàn tất. `SEQ_PHIEU_XUAT` cấp mã `PX0001` theo ADR 0003; khoảng trống sau rollback là hợp lệ.

`CT_PHIEU_XUAT(MaPX, MaLo, MaViTri)` giữ nguồn tồn cụ thể cho từng dòng. Số lượng nguyên dương, đơn giá xuất thực tế `DECIMAL(19,4)` không âm. Sản phẩm được suy ra từ `LO_HANG.MaSP`; không lưu thêm `MaSP` có thể mâu thuẫn. Dòng tham chiếu lô và vị trí, nhưng không FK tới `TON_KHO` vì sau khi xuất hết một cặp vị trí/lô, dòng tồn có thể về 0 hoặc bị xóa trong tương lai trong khi chứng từ phải giữ lịch sử.

Procedure hoàn tất sẽ kiểm tra cặp vị trí/lô thật sự có tồn đủ, lô chưa hết hạn theo ngày nghiệp vụ `Asia/Bangkok`, loại vị trí không phải `Hư hỏng`, đối tác được mapping với mọi sản phẩm, rồi trừ tồn và chuyển trạng thái trong cùng transaction. Gợi ý FEFO chỉ là gợi ý; lúc hoàn tất phải khóa và kiểm tra lại. Lô không hạn đứng sau mọi lô còn hạn, lô hết hạn không được xuất. Chính sách chọn lô cụ thể và mã lỗi sẽ được chốt cùng procedure/API ở mốc tiếp theo.

Chưa có HTTP endpoint hoặc procedure hoàn tất xuất trong commit schema này.
