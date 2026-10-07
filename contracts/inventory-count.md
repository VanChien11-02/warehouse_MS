# Kiểm kê theo vị trí

Trạng thái: Accepted for BE implementation. Owner: backend. Reviewer: chủ repository khi tích hợp.

## Dữ liệu và quyền

Mỗi phiếu kiểm kê thuộc một `maViTri`, có mã `KK0001` theo sequence, nhân viên lập và trạng thái `NHAP`, `DA_HOAN_THANH` hoặc `DA_HUY`. Khi tạo phiếu, server khóa vị trí và lưu một dòng cho từng lô có tồn dương tại thời điểm snapshot. `soLuongHeThong` trên dòng là dữ liệu lịch sử, không tính lại từ tồn hiện tại. Phiếu nháp không thay đổi tồn.

`NhanVienKho` và `QuanLyKho` được lập phiếu, nhập số thực tế và hủy nháp; `QuanLyKho` được hoàn tất; `Admin` và `KeToan` được đọc. `Admin` không có quyền ghi sổ theo DEC-015.

## API

| Method | Route | Nội dung |
| --- | --- | --- |
| `GET` | `/api/phieu-kiem-ke?trangThai=NHAP&maViTri=VT0001&page=0&size=20` | Danh sách có phân trang/lọc trạng thái, vị trí |
| `POST` | `/api/phieu-kiem-ke` | `{ "maViTri": "VT0001", "ghiChu": "Kiểm kê định kỳ" }`; tạo snapshot |
| `GET` | `/api/phieu-kiem-ke/{maPhieuKiemKe}` | Header, các dòng và số lượng hệ thống/thực tế |
| `PUT` | `/api/phieu-kiem-ke/{maPhieuKiemKe}/chi-tiet/{maLo}` | `{ "soLuongThucTe": 8, "lyDoChenhLech": "Hao hụt" }` khi nháp |
| `POST` | `/api/phieu-kiem-ke/{maPhieuKiemKe}/hoan-tat` | Chốt mọi dòng trong một transaction |
| `POST` | `/api/phieu-kiem-ke/{maPhieuKiemKe}/huy` | Hủy phiếu nháp, không đổi tồn |

API dùng JSON `camelCase`, lỗi `{ "code": "...", "message": "..." }`. Không nhận `soLuongHeThong` từ client. Có thể thêm lô đã tồn tại nhưng chưa có tại vị trí lúc snapshot bằng endpoint dòng: server ghi `soLuongHeThong = 0`; khi chốt phải kiểm tra bảo quản, đơn vị và sức chứa. Không tạo lô mới trong quy trình kiểm kê.

`POST` trả `201` kèm `Location`; `GET`/`PUT`/hủy trả phiếu `{maPhieuKiemKe,ngayKiemKe,maNhanVien,maViTri,trangThai,ghiChu,ngayHoanTat,chiTiet}`. Mỗi dòng có `maLo`, `maSanPham`, `tenSanPham`, `soLuongHeThong`, `soLuongThucTe`, `lyDoChenhLech`. `soLuongThucTe` là `null` khi chưa nhập. Danh sách trả `{items,page,size,totalElements,totalPages}`; `page` bắt đầu 0, `size` từ 1 đến 100, sắp theo ngày snapshot mới nhất. Hoàn tất trả `{maPhieuKiemKe,trangThai,ngayHoanTat}`. Các thời điểm HTTP là ISO-8601 UTC với `Z`.

## Quy tắc hoàn tất

- Mọi dòng cần số thực tế không âm; dòng chênh lệch phải có lý do không rỗng (BR-CNT-001/002/004, DEC-018).
- Server khóa phiếu, vị trí và tồn. Tập lô có tồn dương và lượng hiện tại phải bằng snapshot; lô thêm thủ công có snapshot 0 phải vẫn không có tồn tại vị trí. Nếu khác, trả `COUNT_STALE_SNAPSHOT` (HTTP 409); lập phiếu mới để kiểm kê lại. Một vị trí trống không tạo phiếu vì không có gì để đối chiếu.
- Kiểm tra sức chứa, cùng đơn vị tính và bảo quản của mọi lô có tồn sau chốt. Cập nhật tồn, ghi một dòng `BIEN_DONG_TON_KHO` loại `KIEM_KE` cho mỗi chênh lệch khác 0 và chuyển phiếu sang `DA_HOAN_THANH` trong cùng transaction (BR-CNT-003). Lần chốt tiếp theo trả 409 và không ghi sổ thêm.
- `NgayKiemKe` là thời điểm snapshot UTC; `NgayHoanTat` và `NgayGhiSo` là thời điểm ghi sổ UTC. Không sửa/xóa chứng từ đã hoàn tất.
- API truyền tài khoản hiện tại vào `sp_HoanTatKiemKe(@MaPKK, @MaTK = NULL)` để ghi audit `COMPLETE` trong cùng transaction. Lời gọi SQL trực tiếp có thể bỏ `@MaTK`.

Mã lỗi chính: `COUNT_NOT_FOUND` 404, `COUNT_NOT_DRAFT` 409, `COUNT_LINES_REQUIRED` 422, `COUNT_ACTUAL_REQUIRED` 422, `COUNT_REASON_REQUIRED` 422, `COUNT_STALE_SNAPSHOT` 409, `COUNT_CAPACITY_EXCEEDED` 409, `COUNT_UNIT_MISMATCH` 422, `COUNT_STORAGE_MISMATCH` 422. Khi bổ sung endpoint hoặc thay đổi payload phải sửa contract, SQL và test cùng thay đổi.

Mã SQL của procedure: `51401` không thấy phiếu, `51402` phiếu không còn nháp, `51403` thiếu dòng, `51404` thiếu số đếm, `51405` thiếu lý do, `51406` snapshot cũ, `51407` vượt sức chứa, `51408` sai bảo quản, `51409` trộn đơn vị. API không trả nguyên message SQL khi lỗi khác. `INVALID_POSITION`, `INVALID_LOT`, `INVALID_CODE`, `INVALID_STATUS`, `INVALID_PAGINATION`, `INVALID_QUANTITY`, `INVALID_REASON`, `COUNT_CODE_EXHAUSTED` áp dụng khi tạo/nhập dữ liệu. Endpoint ghi cần session và CSRF; sai quyền là 403.
