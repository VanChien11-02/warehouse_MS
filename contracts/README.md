# API contracts

Thư mục này là biên thống nhất giữa `apps/web` và `services/api`.

Mỗi contract cần ghi:

- Trạng thái `Draft` hoặc `Accepted`.
- Owner và reviewer của cả frontend/backend.
- Endpoint, quyền truy cập, request/response và lỗi có cấu trúc.
- Quy tắc ngày giờ, tiền tệ, số lượng và phân trang.
- Thay đổi breaking/non-breaking.

Contract ưu tiên đầu tiên:

1. Session/RBAC.
2. Danh mục sản phẩm/đơn vị tính.
3. Nhập kho và tạo lô.
4. Tra cứu tồn.
5. Xuất kho.
6. Báo cáo tồn kho.

Không dùng JPA entity trực tiếp làm response DTO.
