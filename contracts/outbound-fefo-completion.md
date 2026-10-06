# Contract dữ liệu xuất kho

- Status: Accepted for BE schema/procedure implementation; HTTP API pending
- Date: 2026-10-07
- Scope: OUT-01, BR-OUT-001 đến BR-OUT-007
- Owner triển khai: nhánh BE
- Reviewer tích hợp: repository owner và frontend owner

`PHIEU_XUAT.MaPX CHAR(6)` định danh phiếu xuất. Header giữ đối tác nhận hàng `MaDTNH`, nhân viên lập `MaNV`, thời điểm tạo UTC, ghi chú, trạng thái `NHAP`/`DA_HOAN_THANH`/`DA_HUY` và thời điểm hoàn tất UTC. `NgayHoanTat` chỉ có khi hoàn tất. `SEQ_PHIEU_XUAT` cấp mã `PX0001` theo ADR 0003; khoảng trống sau rollback là hợp lệ.

`CT_PHIEU_XUAT(MaPX, MaLo, MaViTri)` giữ nguồn tồn cụ thể cho từng dòng. Số lượng nguyên dương, đơn giá xuất thực tế `DECIMAL(19,4)` không âm. Sản phẩm được suy ra từ `LO_HANG.MaSP`; không lưu thêm `MaSP` có thể mâu thuẫn. Dòng tham chiếu lô và vị trí, nhưng không FK tới `TON_KHO` vì sau khi xuất hết một cặp vị trí/lô, dòng tồn có thể về 0 hoặc bị xóa trong tương lai trong khi chứng từ phải giữ lịch sử.

`dbo.sp_HoanTatPhieuXuat(@MaPX CHAR(6), @NgayNghiepVu DATE)` khóa phiếu và các vị trí nguồn, kiểm tra cặp vị trí/lô có tồn đủ, lô chưa hết hạn theo ngày nghiệp vụ `Asia/Bangkok`, vị trí không phải `Hư hỏng`, đối tác được mapping với mọi sản phẩm, rồi trừ tồn và chuyển trạng thái trong cùng transaction. `@NgayNghiepVu` do backend tính; không được rỗng. Gợi ý FEFO chỉ là gợi ý; lúc hoàn tất phải khóa và kiểm tra lại theo [ADR 0005](../docs/architecture/adr/0005-outbound-fefo-enforcement.md). Lô không hạn đứng sau mọi lô còn hạn, lô hết hạn không được xuất. Thành công trả result set `maPhieuXuat`, `trangThai`, `ngayHoanTat` UTC.

Mã lỗi SQL ổn định: `51201` không thấy phiếu, `51202` trạng thái sai, `51203` thiếu ngày, `51204` thiếu dòng, `51205` vị trí không tồn tại, `51206` lô/vị trí không khả dụng, `51207` đối tác thiếu mapping, `51208` không đủ tồn, `51209` sai FEFO. JDBC adapter sẽ ánh xạ thành lỗi HTTP có cấu trúc, không trả message SQL thô.

Chưa có HTTP endpoint xuất trong commit procedure này.
