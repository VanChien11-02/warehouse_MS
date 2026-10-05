# ADR 0002: Công nghệ ứng dụng

- Status: Accepted for backend/database; frontend baseline accepted, migration optional
- Date: 2026-09-30

## Decision

### Frontend

Giữ HTML5, CSS3 và Vanilla JavaScript hiện có làm baseline chạy được. Mã nguồn nằm tại `apps/web`.

Vue 3 + TypeScript + Vite là hướng nâng cấp phù hợp khi số module tăng, nhưng chỉ thực hiện bằng backlog item riêng. Migration phải giữ nguyên dashboard, CRUD sản phẩm, phiếu xuất, xử lý lỗi báo cáo và có regression test trước khi xóa baseline cũ.

### Backend

- Java 21 LTS.
- Spring Boot 3.x.
- Spring Web cho REST API.
- Spring Security cho đăng nhập/RBAC.
- Spring JDBC/JdbcTemplate để gọi stored procedure và function quan trọng.
- Spring Data JPA chỉ dùng cho CRUD phù hợp; không để JPA entity trở thành API contract.

Backend tổ chức modular monolith theo package nghiệp vụ:

```text
auth/
catalog/
partner/
warehouse/
inbound/
inventory/
outbound/
transfer/
inventorycount/
returning/
reporting/
audit/
```

Trong mỗi module có thể dùng `api`, `application`, `domain`, `infrastructure` khi độ phức tạp cần thiết. Controller không gọi repository trực tiếp.

### Database

- Microsoft SQL Server 2022 Developer hoặc Express.
- T-SQL cho schema, constraint, trigger, view, index, procedure, function, transaction và phân quyền.
- Script phải chạy lại được từ database sạch và có dữ liệu demo không chứa dữ liệu thật.

## Consequences

- Spring Boot và SQL Server không được thay bằng Node backend hoặc PostgreSQL chỉ vì project tham khảo sử dụng công nghệ đó.
- Logic tồn kho/ghi sổ phải có transaction phía server/database và chống xử lý lặp.
- Frontend gọi API qua adapter; dữ liệu mẫu chỉ dùng cho phát triển và regression.
- Thay đổi framework frontend cần ADR/backlog, kế hoạch migration và bằng chứng không mất hành vi.
