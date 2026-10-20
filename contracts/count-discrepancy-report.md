# Báo cáo chênh lệch kiểm kê

- Status: Accepted for BE implementation
- Scope: REP-01, CNT-01
- Reviewer tích hợp: repository owner và frontend owner

`GET /api/bao-cao/chenh-lech-kiem-ke` dành cho `Admin`, `QuanLyKho`, `KeToan`. Query yêu cầu `tuNgay`, `denNgay` theo `yyyy-MM-dd`, bao gồm hai ngày ở `Asia/Bangkok`; lọc thời điểm hoàn tất phiếu đã đổi sang UTC. Bộ lọc tùy chọn `maKho`, `maViTri` là mã 1–6 chữ/số. `page` bắt đầu 0, `size` từ 1 đến 100.

Response `{tuNgay,denNgay,items,page,size,totalElements,totalPages}`. Mỗi item gồm `maPhieuKiemKe`, `maKho`, `maViTri`, `maLo`, `maSanPham`, `tenSanPham`, `soLuongHeThong`, `soLuongThucTe`, `chenhLech`, `lyDoChenhLech`, `ngayHoanTat`. `chenhLech = soLuongThucTe - soLuongHeThong` là số có dấu; chỉ phiếu `DA_HOAN_THANH` và dòng chênh lệch khác 0 xuất hiện. `ngayHoanTat` là ISO-8601 UTC.

Nguồn đọc là `vw_ChenhLechKiemKe`, không tự tính lại số tồn hệ thống từ `TON_KHO`. Trang sắp theo thời điểm hoàn tất mới nhất, mã phiếu giảm dần, mã lô tăng dần. Ngày thiếu/đảo chiều trả `422 INVALID_DATE_RANGE`; mã hoặc phân trang sai trả `422 INVALID_CODE/INVALID_PAGINATION`; ngày sai định dạng trả `400 INVALID_PARAMETER`; chưa đăng nhập hoặc sai role trả `401/403`.
