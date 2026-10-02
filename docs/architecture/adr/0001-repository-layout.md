# ADR 0001: Cấu trúc repository

- Status: Accepted for baseline
- Date: 2026-09-30
- Decision source: yêu cầu tổ chức lại repository của nhóm

## Context

Frontend, ERD, PDF và tài liệu phân công trước đây nằm lẫn ở root. Cấu trúc này khó chia owner, khó tạo CI và dễ dùng nhầm nội dung từ project bán lẻ tham khảo.

## Decision

Áp dụng cấu trúc monorepo theo mục đích:

```text
apps/web/                 Frontend
services/api/             Spring Boot API
database/                 T-SQL và SQL Server artifacts
contracts/                API contracts
docs/                     Tài liệu hiện hành
scripts/                  Setup/dev/verify
.github/                  Issue, PR và CI
references/               Project khác chỉ để tham khảo
```

Frontend và backend được tổ chức theo feature/module nghiệp vụ. Database có thư mục riêng vì rubric yêu cầu trình bày rõ constraint, trigger, view, index, stored procedure, function, transaction và security script.

## Consequences

- Root chỉ giữ điểm vào dự án và hướng dẫn chung.
- File tham khảo không được dùng như nguồn sự thật của hệ thống kho.
- Khi di chuyển tài liệu phải cập nhật liên kết tương đối và chạy `scripts/verify.ps1`.
- Module mới phải có owner, hướng dẫn chạy và kiểm tra phù hợp.
