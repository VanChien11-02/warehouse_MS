# API contracts

Thư mục này là biên thống nhất giữa `apps/web` và `services/api`.

Baseline quy ước tên, trạng thái, lỗi, interface và stored procedure đang ở trạng thái Draft tại [`BASELINE.md`](BASELINE.md). Nhóm phải giải quyết các mục `Cần chốt` trước khi đổi tài liệu đó sang `Accepted` và tạo bốn branch workstream.

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

Contract chi tiết nên được tách theo resource/use case sau khi baseline được chấp nhận; không dồn toàn bộ endpoint vào một file khó review.
