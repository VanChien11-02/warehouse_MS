# Spring Boot API

Module backend mục tiêu của hệ thống kho.

## Công nghệ cố định

- Java 21 LTS.
- Spring Boot 3.x.
- Spring Web, Spring Security.
- Spring JDBC/JdbcTemplate cho stored procedure/function.
- Spring Data JPA cho CRUD phù hợp.
- Microsoft SQL Server JDBC Driver.

## Kiến trúc đề xuất

Tổ chức package-by-feature dưới package gốc của nhóm:

```text
auth/
catalog/
warehouse/
inbound/
outbound/
inventorycount/
returning/
reporting/
audit/
```

Controller chỉ xử lý HTTP/DTO và gọi application service. Application service điều phối transaction/use case. Domain giữ quy tắc thuần. Infrastructure chứa JDBC/JPA/security adapter.

## Chạy dự kiến

Sau backlog `BE-01`, module phải có Maven Wrapper:

```powershell
services\api\mvnw.cmd spring-boot:run
services\api\mvnw.cmd test
```

Không commit connection string hoặc mật khẩu SQL Server. Cung cấp `.env.example` hoặc cấu hình mẫu không chứa secret.
