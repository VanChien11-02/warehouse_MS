# ADR 0003: Quy ước nền tảng cho triển khai backend

- Status: Accepted for BE implementation
- Date: 2026-10-05
- Scope: `DEC-001` đến `DEC-010` trong `OPEN_DECISIONS.md`

Các quyết định này được chốt cho nhánh triển khai backend theo quyền kỹ thuật đã được giao. Trạng thái này không thay cho bước review và tích hợp của chủ repository. Khi đổi một quyết định, cập nhật contract, code, test và tài liệu liên quan trong cùng thay đổi.

| ID | Quyết định | Cách áp dụng |
| --- | --- | --- |
| DEC-001 | URL tài nguyên dùng chữ thường và kebab-case, ví dụ `/api/san-pham`. | Frontend adapter và backend dùng cùng đường dẫn; không giữ hai URL lâu dài. |
| DEC-002 | Chứng từ có `NHAP`, `DA_HOAN_THANH`, `DA_HUY`; chưa thêm `CHO_DUYET`. | Chỉ `NHAP` được sửa; hoàn tất/hủy là chuyển trạng thái một chiều. Quyền hoàn tất do security kiểm tra. |
| DEC-003 | Thời điểm lưu UTC bằng `DATETIME2(3)`; API trả ISO-8601 với `Z`. Ngày nghiệp vụ và bộ lọc báo cáo dùng `Asia/Bangkok`. | Backend đổi ranh giới ngày địa phương sang UTC trước khi truy vấn. Trường chỉ có ngày dùng SQL `DATE` và JSON `yyyy-MM-dd`. |
| DEC-004 | `400` cho payload sai cú pháp/kiểu; `422` cho validation nghiệp vụ gắn với field; `409` cho mã trùng, trạng thái xung đột, thiếu tồn và hoàn tất lặp. | API luôn trả error envelope trong contract; `401`/`403` theo trạng thái xác thực/quyền. |
| DEC-005 | Procedure thành công trả result set có mã chứng từ, trạng thái và thời điểm hoàn tất; lỗi dùng `THROW` với số ổn định trong dải `51000–51999`. | JDBC adapter ánh xạ số lỗi thành mã lỗi API; không trả message SQL thô cho frontend. |
| DEC-006 | Database baseline tên `BlueStock`, schema ứng dụng `dbo`. | `init.sql`, cấu hình mẫu và hướng dẫn demo dùng cùng tên. Script dừng nếu database đã tồn tại. |
| DEC-007 | Mã danh mục do người dùng nhập, chuẩn hóa chữ hoa và kiểm tra trùng ở server/database. Mã chứng từ và lô do server sinh từ SQL sequence theo từng loại. | Mã công khai giữ `CHAR(6)` theo ERD; sequence có thể có khoảng trống sau rollback, không dùng mã để suy ra thứ tự thời gian. |
| DEC-008 | Tiền dùng SQL `DECIMAL(19,4)` và Java `BigDecimal`. | Không dùng `FLOAT`/`double`; API truyền JSON number; làm tròn chỉ tại quy tắc nghiệp vụ hoặc hiển thị. |
| DEC-009 | Đăng nhập bằng session phía server và cookie `HttpOnly`; thao tác ghi dùng CSRF token. | Local web và API cùng hostname `127.0.0.1` ở hai port, CORS chỉ cho phép origin đã cấu hình và credentials. Logout hủy session. Production dùng HTTPS và cookie `Secure`. |
| DEC-010 | `sqlcmd` là runner chuẩn cho baseline SQL, chạy từ root repository với `-b`; SSMS cần SQLCMD mode. | `init.sql` điều phối file bằng `:r`; test SQL chạy qua `scripts/verify.ps1 -WithDatabase`. |

Các endpoint và DTO cụ thể vẫn phải có contract riêng trước khi được coi là hoàn thành. ADR này chỉ khóa quy ước dùng chung để bắt đầu triển khai.
