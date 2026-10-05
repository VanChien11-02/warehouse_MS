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

Các package được gom ownership theo bốn workstream trong [`../../docs/project/governance/WORKSTREAMS.md`](../../docs/project/governance/WORKSTREAMS.md). Package khác chỉ được import public DTO/interface của feature; không import controller, repository, JPA entity hoặc implementation nội bộ.

Các interface liên module và quy ước HTTP đang được thảo luận tại [`../../contracts/BASELINE.md`](../../contracts/BASELINE.md). Ví dụ trong contract chỉ trở thành bắt buộc sau khi tài liệu chuyển sang `Accepted` và chữ ký thật đã compile trong project.

Trước khi khởi tạo package hoặc endpoint, đọc thêm [`../../docs/architecture/MODULE_CATALOG.md`](../../docs/architecture/MODULE_CATALOG.md), [`../../contracts/API_CATALOG.md`](../../contracts/API_CATALOG.md) và [`../../docs/requirements/BUSINESS_RULES.md`](../../docs/requirements/BUSINESS_RULES.md).

Controller chỉ xử lý HTTP/DTO và gọi application service. Application service điều phối transaction/use case. Domain giữ quy tắc thuần. Infrastructure chứa JDBC/JPA/security adapter.

## Chạy dự kiến

Sau backlog `BE-01`, module phải có Maven Wrapper:

```powershell
services\api\mvnw.cmd spring-boot:run
services\api\mvnw.cmd test
```

Không commit connection string hoặc mật khẩu SQL Server. Cung cấp `.env.example` hoặc cấu hình mẫu không chứa secret.
