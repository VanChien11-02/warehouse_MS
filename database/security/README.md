# Database roles

`001_application_roles.sql` tạo bốn role SQL Server; `002_role_policy_20261022.sql`
điều chỉnh quyền theo quyết định hiện hành và cấp quyền đối soát. `init.sql`
chạy cả hai script; migration 028 chạy phần điều chỉnh cho database cũ.
Các script không tạo login/user và không chứa mật khẩu. Người vận hành
tạo user riêng, rồi gán bằng `ALTER ROLE ... ADD MEMBER ...` khi cần truy cập
database trực tiếp. Có thể chạy lại script sau migration; quyền được cấp theo
object cụ thể, không cấp `SELECT` toàn schema để tránh lộ hash tài khoản.

| Role SQL | Đọc | Ghi trực tiếp |
| --- | --- | --- |
| `wms_admin` | Nhân viên và cột tài khoản không chứa hash | Nhân viên, tài khoản |
| `wms_manager` | Danh mục, chứng từ, tồn, báo cáo | Danh mục, phiếu nháp; thực thi năm procedure hoàn tất |
| `wms_staff` | Danh mục, phiếu nhập/xuất và tồn | Phiếu nhập/xuất nháp; bị từ chối thực thi procedure hoàn tất |
| `wms_accountant` | Danh mục, chứng từ, tồn, báo cáo giá trị và kết quả đối soát | Ghi một kết quả đối soát; không sửa/xóa kết quả |

Không role nào được đọc hoặc ghi audit trực tiếp. API kiểm tra phiếu đã hoàn tất,
giá trị tính từ chi tiết, ghi chú chênh lệch và chống đối soát lặp trước khi ghi.
Các role SQL dùng cho kết nối trực tiếp vào DB. Session/RBAC của API Spring
vẫn kiểm soát HTTP riêng; tài khoản kết nối của API phải được người triển khai
cấp quyền phù hợp để xác thực, lập phiếu và ghi audit qua các use case đã kiểm
thử. Không gán API principal vào role nhân viên kho vì sẽ chặn các procedure
mà service cần gọi.

Test `database/tests/022_application_roles.sql` tạo user SQL không có login,
kiểm tra quyền hiệu lực bằng `EXECUTE AS USER`, kiểm tra GRANT/REVOKE/DENY,
rồi xóa các user tạm. Chạy qua `scripts/verify.ps1 -WithDatabase`.
