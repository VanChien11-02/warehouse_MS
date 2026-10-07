# Nhật ký thao tác

- Status: Accepted for BE schema implementation
- Scope: AUD-01, BR-AUD-001/002
- Reviewer tích hợp: repository owner và frontend owner

`LICH_SU_THAO_TAC` lưu `MaLichSu BIGINT IDENTITY`, `MaTK` của người thao tác, thời điểm UTC, hành động, tên bảng, mã bản ghi và JSON trước/sau nếu cần. Hành động thuộc `CREATE`, `UPDATE`, `CANCEL`, `COMPLETE`, `PASSWORD_CHANGE`, `PASSWORD_RESET`. JSON phải hợp lệ; không lưu mật khẩu, hash, CSRF token, cookie, connection string hoặc toàn bộ request body. Chỉ ghi trường nghiệp vụ an toàn cần truy vết.

Index `(ThoiGian DESC, MaTK)` phục vụ tra cứu theo thời gian và tài khoản. Ghi audit trong cùng transaction với thay đổi nghiệp vụ khi thao tác bắt đầu từ API. Procedure gọi trực tiếp ngoài API không có tài khoản ứng dụng nên không tự ghi `MaTK` giả.

API dự kiến `GET /api/audit` chỉ dành cho `Admin`, phân trang và lọc tài khoản/khoảng thời gian. Không có API xóa hoặc sửa audit.
