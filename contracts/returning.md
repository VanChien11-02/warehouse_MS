# Trả hàng sau xuất

- Status: Accepted for BE schema implementation
- Scope: RET-01, BR-RET-001 đến BR-RET-005
- Reviewer tích hợp: repository owner và frontend owner

`PHIEU_TRA_HANG.MaPTH CHAR(6)` tham chiếu `PHIEU_XUAT.MaPX` gốc; đối tác nhận hàng được suy ra từ phiếu xuất. Header lưu nhân viên nhận trả, thời điểm UTC, trạng thái `NHAP`, `DA_HOAN_THANH`, `DA_HUY`, ghi chú và thời điểm hoàn tất UTC. `SEQ_PHIEU_TRA_HANG` cấp mã `TH0001`. Khoảng trống số do rollback là hợp lệ.

`CT_PHIEU_TRA_HANG` có khóa `(MaPTH, MaLo)`, đích `MaViTri`, lượng nguyên dương và `TinhTrang` chỉ nhận `Tốt` hoặc `Hư hỏng`. Một lô chỉ có một dòng trên một phiếu; để trả cùng lô ở hai tình trạng phải lập hai phiếu. Chỉ lô từng xuất trong phiếu gốc được trả. Tổng lượng của một lô qua các phiếu trả đã hoàn tất cộng lượng phiếu đang chốt không vượt tổng lượng xuất của lô ở phiếu gốc, kể cả phiếu xuất có nhiều vị trí nguồn.

`Tốt` chỉ vào vị trí khác loại `Hư hỏng`; `Hư hỏng` chỉ vào vị trí loại `Hư hỏng` và không khả dụng cho xuất FEFO. Vị trí nhận phải phù hợp yêu cầu bảo quản, sức chứa và đơn vị tính theo ADR 0004. Hoàn tất dùng transaction, khóa phiếu xuất gốc để tuần tự hóa các phiếu trả cùng nguồn, tăng tồn và ghi sổ `TRA_HANG` cùng transaction. Hoàn tất lặp trả conflict; phiếu hoàn tất không sửa hoặc xóa.

API dự kiến: `GET/POST /api/phieu-tra-hang`, `GET/PUT /api/phieu-tra-hang/{maPhieuTraHang}`, `POST /api/phieu-tra-hang/{maPhieuTraHang}/huy`, `POST /api/phieu-tra-hang/{maPhieuTraHang}/hoan-tat`. `NhanVienKho`/`QuanLyKho` lập và sửa nháp; chỉ `QuanLyKho` hoàn tất; `Admin`/`KeToan` đọc. Payload và lỗi HTTP chi tiết sẽ được bổ sung cùng API.
