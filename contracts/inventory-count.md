# Kiểm kê theo vị trí

Trạng thái: contract triển khai CNT-01. Owner: backend. Reviewer: chủ repository khi tích hợp.

## Dữ liệu và quyền

Mỗi phiếu kiểm kê thuộc một `maViTri`, có mã `KK0001` theo sequence, nhân viên lập và trạng thái `NHAP`, `DA_HOAN_THANH` hoặc `DA_HUY`. Khi tạo phiếu, server khóa vị trí và lưu một dòng cho từng lô có tồn dương tại thời điểm snapshot. `soLuongHeThong` trên dòng là dữ liệu lịch sử, không tính lại từ tồn hiện tại. Phiếu nháp không thay đổi tồn.

`NhanVienKho` và `QuanLyKho` được lập phiếu, nhập số thực tế và hủy nháp; `QuanLyKho` được hoàn tất; `Admin` và `KeToan` được đọc. `Admin` không có quyền ghi sổ theo DEC-015.

## API dự kiến

| Method | Route | Nội dung |
| --- | --- | --- |
| `GET` | `/api/phieu-kiem-ke` | Danh sách có phân trang/lọc trạng thái, vị trí |
| `POST` | `/api/phieu-kiem-ke` | `{ "maViTri": "VT0001", "ghiChu": "Kiểm kê định kỳ" }`; tạo snapshot |
| `GET` | `/api/phieu-kiem-ke/{maPhieuKiemKe}` | Header, các dòng và số lượng hệ thống/thực tế |
| `PUT` | `/api/phieu-kiem-ke/{maPhieuKiemKe}/chi-tiet/{maLo}` | `{ "soLuongThucTe": 8, "lyDoChenhLech": "Hao hụt" }` khi nháp |
| `POST` | `/api/phieu-kiem-ke/{maPhieuKiemKe}/hoan-tat` | Chốt mọi dòng trong một transaction |
| `POST` | `/api/phieu-kiem-ke/{maPhieuKiemKe}/huy` | Hủy phiếu nháp, không đổi tồn |

API dùng JSON `camelCase`, lỗi `{ "code": "...", "message": "..." }`. Không nhận `soLuongHeThong` từ client. Có thể thêm lô đã tồn tại nhưng chưa có tại vị trí lúc snapshot bằng endpoint dòng: server ghi `soLuongHeThong = 0`; khi chốt phải kiểm tra bảo quản, đơn vị và sức chứa. Không tạo lô mới trong quy trình kiểm kê.

## Quy tắc hoàn tất

- Mọi dòng cần số thực tế không âm; dòng chênh lệch phải có lý do không rỗng (BR-CNT-001/002/004, DEC-018).
- Server khóa phiếu, vị trí và tồn. Tập lô có tồn dương và lượng hiện tại phải bằng snapshot; lô thêm thủ công có snapshot 0 phải vẫn không có tồn tại vị trí. Nếu khác, trả `COUNT_STALE_SNAPSHOT` (HTTP 409); lập phiếu mới để kiểm kê lại. Một vị trí trống không tạo phiếu vì không có gì để đối chiếu.
- Kiểm tra sức chứa, cùng đơn vị tính và bảo quản của mọi lô có tồn sau chốt. Cập nhật tồn, ghi một dòng `BIEN_DONG_TON_KHO` loại `KIEM_KE` cho mỗi chênh lệch khác 0 và chuyển phiếu sang `DA_HOAN_THANH` trong cùng transaction (BR-CNT-003). Lần chốt tiếp theo trả 409 và không ghi sổ thêm.
- `NgayKiemKe` là thời điểm snapshot UTC; `NgayHoanTat` và `NgayGhiSo` là thời điểm ghi sổ UTC. Không sửa/xóa chứng từ đã hoàn tất.

Mã lỗi chính: `COUNT_NOT_FOUND` 404, `COUNT_NOT_DRAFT` 409, `COUNT_LINES_REQUIRED` 422, `COUNT_ACTUAL_REQUIRED` 422, `COUNT_REASON_REQUIRED` 422, `COUNT_STALE_SNAPSHOT` 409, `COUNT_CAPACITY_EXCEEDED` 409, `COUNT_UNIT_MISMATCH` 422, `COUNT_STORAGE_MISMATCH` 422. Khi bổ sung endpoint hoặc thay đổi payload phải sửa contract, SQL và test cùng thay đổi.
