# Contract báo cáo nhập–xuất–tồn

- Status: Accepted for BE implementation
- Date: 2026-10-07
- Scope: REP-01, BR-REP-001 đến BR-REP-004
- Owner triển khai: nhánh BE
- Reviewer tích hợp: repository owner và frontend owner

`GET /api/bao-cao/nhap-xuat` chỉ dành cho `Admin`, `QuanLyKho`, `KeToan`; `NhanVienKho` nhận `403` vì response có giá trị tiền. Request yêu cầu `tuNgay`, `denNgay` theo `yyyy-MM-dd`, bao gồm cả hai ngày tại `Asia/Bangkok`. Backend đổi đầu ngày `tuNgay` và đầu ngày sau `denNgay` sang UTC, rồi lọc `NgayGhiSo >= startUtc` và `< endUtc`. `tuNgay > denNgay` hoặc thiếu ngày trả `422 INVALID_DATE_RANGE`; ngày sai kiểu trả `400 INVALID_PARAMETER`.

Lọc tùy chọn `maKho`, `maSanPham` (mã 1–6 chữ/số, chuẩn hóa hoa); `page` bắt đầu 0, `size` từ 1 đến 100. Lỗi mã hoặc phân trang trả `422 INVALID_CODE/INVALID_PAGINATION`. Danh sách chỉ gồm cặp kho/sản phẩm có ít nhất một biến động trước cuối kỳ; không tạo dòng 0 giả cho sản phẩm chưa từng ghi sổ.

Ví dụ: `GET /api/bao-cao/nhap-xuat?tuNgay=2026-10-01&denNgay=2026-10-31&maKho=KHO001&page=0&size=20`.

Response có `tuNgay`, `denNgay`, `items`, `page`, `size`, `totalElements`, `totalPages`. Mỗi item gồm `maKho`, `tenKho`, `maSanPham`, `tenSanPham`, `maDonViTinh`, `soLuongDauKy`, `soLuongNhap`, `soLuongXuat`, `soLuongDieuChinh`, `soLuongCuoiKy`, `giaTriDauKy`, `giaTriNhap`, `giaTriXuat`, `giaTriDieuChinh`, `giaTriCuoiKy`. Số lượng dùng số nguyên; tiền là JSON number từ `DECIMAL(38,4)` tổng hợp, không làm tròn trước khi cộng. `soLuongXuat`/`giaTriXuat` là số dương để đọc, còn sổ biến động lưu delta âm. `soLuongDieuChinh`/`giaTriDieuChinh` là delta có dấu của mọi loại nghiệp vụ khác `NHAP` và `XUAT` (chuyển, kiểm kê, trả). Luôn có `cuoiKy = dauKy + nhap - xuat + dieuChinh` theo từng cặp kho/sản phẩm.

Nguồn là `BIEN_DONG_TON_KHO` qua `vw_BienDongTonKhoChiTiet`; chỉ transaction hoàn tất mới ghi dòng. Giá trị biến động dùng `CT_PHIEU_NHAP.DonGiaNhap` của lô tạo từ phiếu nhập, không dùng giá sản phẩm hiện tại hoặc giá bán trên phiếu xuất. Chuyển kho trong tương lai ghi hai delta theo vị trí nguồn/đích để báo cáo từng kho chính xác. Báo cáo chỉ đọc, không sửa bảng nghiệp vụ.
