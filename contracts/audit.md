# Nhật ký thao tác

- Status: Accepted for BE implementation
- Scope: AUD-01, BR-AUD-001/002
- Reviewer tích hợp: repository owner và frontend owner

`LICH_SU_THAO_TAC` lưu `MaLichSu BIGINT IDENTITY`, `MaTK` của người thao tác, thời điểm UTC, hành động, tên bảng, mã bản ghi và JSON trước/sau nếu cần. Hành động thuộc `CREATE`, `UPDATE`, `CANCEL`, `COMPLETE`, `PASSWORD_CHANGE`, `PASSWORD_RESET`. JSON phải hợp lệ; không lưu mật khẩu, hash, CSRF token, cookie, connection string hoặc toàn bộ request body. Chỉ ghi trường nghiệp vụ an toàn cần truy vết.

API quản trị nhân viên/tài khoản ghi `CREATE`/`UPDATE` với response DTO an toàn trước/sau trong cùng transaction; đổi và reset mật khẩu chỉ ghi hành động, không ghi giá trị mật khẩu hoặc hash. Nếu ghi audit thất bại, thay đổi quản trị rollback.

Hoàn tất nhập qua API truyền `MaTK` của session vào `sp_HoanTatPhieuNhap`; procedure ghi `COMPLETE` cho `PHIEU_NHAP` trong cùng transaction với lô, tồn và sổ biến động. Gọi procedure trực tiếp không có `MaTK` vẫn được để kiểm thử/nhập dữ liệu có kiểm soát, nhưng không tạo actor giả.

Hoàn tất xuất qua API truyền actor vào `sp_HoanTatPhieuXuat`; audit `COMPLETE` của `PHIEU_XUAT` cùng transaction với trừ tồn và sổ biến động.

Hoàn tất chuyển qua API truyền actor vào `sp_HoanTatChuyenKho`; audit `COMPLETE` của `PHIEU_CHUYEN_KHO` cùng transaction với hai phía tồn.

Hoàn tất kiểm kê qua API truyền actor vào `sp_HoanTatKiemKe`; audit `COMPLETE` của `PHIEU_KIEM_KE` cùng transaction với điều chỉnh tồn.

Hoàn tất trả hàng qua API truyền actor vào `sp_HoanTatTraHang`; audit `COMPLETE` của `PHIEU_TRA_HANG` cùng transaction với tăng tồn và sổ biến động.

Hủy phiếu nhập nháp qua API ghi `CANCEL` của `PHIEU_NHAP` trong cùng transaction với đổi trạng thái. Chỉ ghi trạng thái cũ/mới; hủy lặp trả conflict và không ghi thêm audit.

Hủy phiếu xuất nháp qua API ghi `CANCEL` của `PHIEU_XUAT` cùng transaction; hủy lặp không tạo nhật ký mới.

Hủy phiếu chuyển nháp qua API ghi `CANCEL` của `PHIEU_CHUYEN_KHO` cùng transaction; hủy lặp không tạo nhật ký mới.

Index `(ThoiGian DESC, MaTK)` phục vụ tra cứu theo thời gian và tài khoản. Ghi audit trong cùng transaction với thay đổi nghiệp vụ khi thao tác bắt đầu từ API. Procedure gọi trực tiếp ngoài API không có tài khoản ứng dụng nên không tự ghi `MaTK` giả.

`GET /api/audit?tuNgay=2026-10-01&denNgay=2026-10-31&maTaiKhoan=TK0001&page=0&size=20` chỉ dành cho `Admin`. Hai ngày theo `yyyy-MM-dd` là bắt buộc, bao gồm cả hai ngày ở `Asia/Bangkok`; server đổi sang UTC để lọc `ThoiGian`. `maTaiKhoan` tùy chọn, `page` bắt đầu 0, `size` từ 1 đến 100. Kết quả sắp `ThoiGian DESC, MaLichSu DESC`, trả `{tuNgay,denNgay,items,page,size,totalElements,totalPages}`. Item gồm `maLichSu`, `maTaiKhoan`, `thoiGian` ISO-8601 UTC, `hanhDong`, `tenBang`, `maBanGhi`, `duLieuCu`, `duLieuMoi`; hai trường dữ liệu là chuỗi JSON hoặc `null`.

Ngày thiếu/đảo chiều trả `422 INVALID_DATE_RANGE`, mã/phân trang sai trả `422 INVALID_CODE/INVALID_PAGINATION`, ngày sai kiểu trả `400 INVALID_PARAMETER`; role khác nhận 403. Không có API xóa hoặc sửa audit.
