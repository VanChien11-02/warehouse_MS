# Trả hàng sau xuất

- Status: Accepted for BE implementation
- Scope: RET-01, BR-RET-001 đến BR-RET-005
- Reviewer tích hợp: repository owner và frontend owner

`PHIEU_TRA_HANG.MaPTH CHAR(6)` tham chiếu `PHIEU_XUAT.MaPX` gốc; đối tác nhận hàng được suy ra từ phiếu xuất. Header lưu nhân viên nhận trả, thời điểm UTC, trạng thái `NHAP`, `DA_HOAN_THANH`, `DA_HUY`, ghi chú và thời điểm hoàn tất UTC. `SEQ_PHIEU_TRA_HANG` cấp mã `TH0001`. Khoảng trống số do rollback là hợp lệ.

`CT_PHIEU_TRA_HANG` có khóa `(MaPTH, MaLo)`, đích `MaViTri`, lượng nguyên dương và `TinhTrang` chỉ nhận `Tốt` hoặc `Hư hỏng`. Một lô chỉ có một dòng trên một phiếu; để trả cùng lô ở hai tình trạng phải lập hai phiếu. Chỉ lô từng xuất trong phiếu gốc được trả. Tổng lượng của một lô qua các phiếu trả đã hoàn tất cộng lượng phiếu đang chốt không vượt tổng lượng xuất của lô ở phiếu gốc, kể cả phiếu xuất có nhiều vị trí nguồn.

`Tốt` chỉ vào vị trí khác loại `Hư hỏng`; `Hư hỏng` chỉ vào vị trí loại `Hư hỏng` và không khả dụng cho xuất FEFO. Vị trí nhận phải phù hợp yêu cầu bảo quản, sức chứa và đơn vị tính theo ADR 0004. Hoàn tất dùng transaction, khóa phiếu xuất gốc để tuần tự hóa các phiếu trả cùng nguồn, tăng tồn và ghi sổ `TRA_HANG` cùng transaction. Hoàn tất lặp trả conflict; phiếu hoàn tất không sửa hoặc xóa.

`dbo.sp_HoanTatTraHang(@MaPTH CHAR(6), @MaTK CHAR(6) = NULL)` trả `maPhieuTraHang`, `trangThai`, `ngayHoanTat` UTC. Mã lỗi SQL: `51501` không thấy phiếu, `51502` không còn nháp, `51503` thiếu dòng, `51504` phiếu xuất gốc chưa hoàn tất, `51505` lô chưa xuất/trả vượt, `51506` vị trí/tình trạng/bảo quản sai, `51507` vượt sức chứa, `51508` trộn đơn vị tính. Lỗi ghi sổ cuối transaction rollback toàn bộ tồn và trạng thái.

HTTP API dùng session/CSRF chung:

| Method | Route | Quyền | Kết quả |
| --- | --- | --- | --- |
| `POST` | `/api/phieu-tra-hang` | `QuanLyKho`, `NhanVienKho` | `201` phiếu `NHAP`, `Location` |
| `GET` | `/api/phieu-tra-hang/{maPhieuTraHang}` | Bốn role đã đăng nhập | `200` header và dòng |
| `GET` | `/api/phieu-tra-hang?trangThai=NHAP&maPhieuXuat=PX0001&page=0&size=20` | Bốn role đã đăng nhập | `200` danh sách header phân trang |
| `PUT` | `/api/phieu-tra-hang/{maPhieuTraHang}` | `QuanLyKho`, `NhanVienKho` | `200` phiếu nháp sau thay ghi chú/dòng |
| `POST` | `/api/phieu-tra-hang/{maPhieuTraHang}/huy` | `QuanLyKho`, `NhanVienKho` | `200` phiếu `DA_HUY` |
| `POST` | `/api/phieu-tra-hang/{maPhieuTraHang}/hoan-tat` | Chỉ `QuanLyKho` | `200` mã, trạng thái, thời điểm UTC |

Tạo nháp: `{"maPhieuXuat":"PX0001","ghiChu":null,"chiTiet":[{"maLo":"LO0001","maViTri":"VT0001","soLuong":2,"tinhTrang":"Tốt"}]}`. Phiếu xuất gốc phải hoàn tất. Nhân viên lấy từ session, mã phiếu do server cấp. `PUT` nhận `ghiChu` và `chiTiet` như trên, không đổi phiếu xuất gốc. Dòng phải có lô/vị trí hợp lệ, lượng dương và tình trạng đúng enum; mỗi lô một dòng. Nháp không ghi tồn, có thể hủy; hoàn tất/hủy rồi không sửa tiếp.

Response chi tiết gồm `maPhieuTraHang`, `ngayTra`, `maPhieuXuat`, `maNhanVien`, `trangThai`, `ghiChu`, `ngayHoanTat`, `chiTiet`. Dòng thêm `maSanPham` và `tenSanPham`. Danh sách trả `{items,page,size,totalElements,totalPages}`, `page` bắt đầu 0, `size` 1–100, sắp ngày tạo mới nhất. Thời điểm ISO-8601 UTC với `Z`.

Lỗi HTTP: `404 RETURN_NOT_FOUND`, `OUTBOUND_NOT_FOUND`; `409 RETURN_NOT_DRAFT`, `OUTBOUND_NOT_COMPLETED`, `RETURN_LIMIT_EXCEEDED`, `CAPACITY_EXCEEDED`, `UNIT_MISMATCH`, `RETURN_CODE_EXHAUSTED`; `422 LINES_REQUIRED`, `INVALID_QUANTITY`, `INVALID_CONDITION`, `DUPLICATE_RETURN_LINE`, `INVALID_REFERENCE`, `INCOMPATIBLE_STORAGE`, `INVALID_CODE`, `INVALID_STATUS`, `INVALID_PAGINATION`, `VALIDATION_FAILED`. Sai quyền/CSRF trả 403. Lỗi SQL không nhận diện trả `500 RETURN_POSTING_FAILED` mà không lộ message SQL.
