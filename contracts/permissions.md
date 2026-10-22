# Ma trận quyền hệ thống

- Status: Accepted for implementation theo quyết định phân vai 2026-10-22.
- Scope: SEC-01, DB-R04, FE-02.
- Owner: backend/frontend. Reviewer: chủ repository khi tích hợp.

`GET /api/quyen-han` chỉ dành cho `ADMIN`, trả `200` mảng bốn vai trò.
Chưa đăng nhập trả `401`; các vai trò khác trả `403`. Chỉ có API đọc ma trận;
quyền thực thi vẫn được kiểm tra bởi Spring Security. Không có schema hoặc
migration mới vì tập vai trò vẫn là `ADMIN`, `QLKHO`, `NVKHO`, `KETOAN`.

Mỗi phần tử có `role`, `tenVaiTro`, `permissions`. Mỗi quyền gồm `module`,
`tenChucNang` và năm boolean `xem`, `tao`, `sua`, `xoaHoacHuy`, `hoanTat`.

| Phạm vi | ADMIN | QLKHO | NVKHO | KETOAN |
| --- | --- | --- | --- | --- |
| Nhân viên, tài khoản | Đọc/tạo/sửa/khóa/gán role | Không | Không | Không |
| Sản phẩm, loại, đơn vị, kho/khu vực/vị trí, đối tác | Không | CRUD | Đọc để lập phiếu/đối chiếu | Đọc để đối chiếu |
| Phiếu nhập, phiếu xuất | Không | Lập/sửa/hủy nháp và hoàn tất | Lập/sửa/hủy nháp | Đọc |
| Phiếu chuyển, kiểm kê, trả hàng | Không | Lập/sửa/hủy nháp và hoàn tất | Không | Đọc |
| Tồn kho | Không | Đọc | Đọc | Đọc |
| Nhập–xuất–tồn, chênh lệch kiểm kê | Không | Đọc | Không | Đọc |
| Lô sắp hết hạn | Không | Đọc | Không | Không |
| Đối soát giá trị phiếu nhập/xuất đã hoàn tất | Không | Đọc kết quả | Không | Xác nhận khớp hoặc ghi nhận chênh lệch một lần |
| Ma trận quyền | Đọc | Không | Không | Không |
| Audit | Không | Không | Không | Không |

Gán vai trò dùng `PUT /api/tai-khoan/{maTaiKhoan}` trong
[`identity-admin.md`](identity-admin.md); không tạo vai trò tùy ý từ giao diện.
Nhân viên/tài khoản không xóa vật lý. CRUD danh mục chỉ xóa khi chưa có tham chiếu.
Chứng từ chỉ sửa/hủy khi nháp; hoàn tất kiểm kê điều chỉnh tồn qua procedure.

Giao diện Admin có bộ chọn bốn vai trò và bảng theo chức năng, nút chuyển tới
tài khoản để gán vai trò. Ma trận là bản mô tả chính sách của backend; khi sửa
`SecurityConfig` phải cập nhật `PermissionService`, contract và kiểm tra quyền.

Kế toán đối soát giá trị phiếu nhập/xuất đã hoàn tất qua
[`accounting-reconciliation.md`](accounting-reconciliation.md). Kế toán không
được sửa, hủy hoặc hoàn tất chứng từ kho; đối soát không thay đổi tồn.
`GET /api/audit` không cấp cho bốn vai trò hiện tại.
