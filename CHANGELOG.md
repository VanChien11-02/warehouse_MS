# Changelog

Các thay đổi đáng chú ý của dự án được ghi tại đây.

## Unreleased

### Added

- Schema SQL Server 27 bảng với năm procedure hoàn tất chứng từ, năm function, bảy view, trigger bảo vệ vị trí, index tra cứu và bốn database role.
- API Java 21/Spring Boot cho session/RBAC, quản trị tài khoản, danh mục/kho/đối tác, nhập, xuất FEFO, chuyển, kiểm kê, trả hàng, tồn, báo cáo và audit.
- Seed dữ liệu giả có thể chạy lại, bài kiểm tra SQL cho ràng buộc/transaction/quyền và bài tranh chấp xuất kho hai session.
- Kịch bản kiểm thử HTTP và bằng chứng kiểm chứng local; E2E JDBC/HTTP cần SQL Server bật TCP/IP.
- Cấu trúc monorepo gồm `apps`, `services`, `database`, `contracts`, `docs`, `scripts` và `.github`.
- Hướng dẫn làm việc, đóng góp, backlog, phân công và ADR công nghệ dành riêng cho hệ thống kho.
- Script PowerShell thống nhất để kiểm tra môi trường, chạy frontend và xác minh baseline.
- Draft kế hoạch bốn workstream, branch ownership và ranh giới module để nhóm thảo luận trước khi phát triển song song.
- Draft contract baseline cho quy ước tên, trạng thái chứng từ, HTTP, interface Java và stored procedure.
- Bộ context để build gồm project briefing, kiến trúc hệ thống, module catalog, business rules, build guide, API catalog, schema plan và danh sách quyết định còn mở.

### Changed

- Tách cấu hình điều hướng và dữ liệu mẫu frontend thành module JavaScript riêng; giao diện vẫn dùng dữ liệu demo.
- Chuyển frontend baseline vào `apps/web`.
- Chuyển ERD, PDF nguồn và tài liệu quản trị vào `docs`.
- Chuyển project bán lẻ tham khảo vào `references/retail-management` và đánh dấu chỉ dùng tham khảo.
- Bổ sung backlog khóa contract và tách frontend theo feature trước khi bốn branch cùng phát triển.
- Làm rõ danh sách package backend với `partner`, `inventory` và `transfer`, thống nhất tên package xác thực là `auth`.

### Preserved

- Backend mục tiêu tiếp tục dùng Spring Boot.
- Database mục tiêu tiếp tục dùng Microsoft SQL Server.
- Frontend Vanilla JavaScript đang chạy được giữ nguyên làm baseline.
