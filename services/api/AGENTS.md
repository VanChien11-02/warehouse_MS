# Hướng dẫn Spring Boot API

Đọc API contract, ERD và backlog item trước khi tạo controller hoặc migration.

- Tổ chức package-by-feature; không gom toàn bộ controller/service/repository của mọi nghiệp vụ vào package dùng chung.
- Controller chỉ xử lý HTTP/DTO; không gọi repository trực tiếp.
- Application service là transaction boundary; domain không phụ thuộc HTTP/JPA.
- Không trả JPA entity trực tiếp cho frontend.
- Stored procedure/function quan trọng được gọi qua adapter JDBC có test integration.
- Mặc định từ chối truy cập; endpoint phải khai báo role/quyền rõ ràng.
- Không log mật khẩu, token, connection string hoặc dữ liệu nhạy cảm.
- Thay đổi API phải cập nhật `contracts/`, test provider và consumer liên quan.
