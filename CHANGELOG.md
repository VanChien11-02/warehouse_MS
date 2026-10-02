# Changelog

Các thay đổi đáng chú ý của dự án được ghi tại đây.

## Unreleased

### Added

- Cấu trúc monorepo gồm `apps`, `services`, `database`, `contracts`, `docs`, `scripts` và `.github`.
- Hướng dẫn làm việc, đóng góp, backlog, phân công và ADR công nghệ dành riêng cho hệ thống kho.
- Script PowerShell thống nhất để kiểm tra môi trường, chạy frontend và xác minh baseline.

### Changed

- Chuyển frontend baseline vào `apps/web`.
- Chuyển ERD, PDF nguồn và tài liệu quản trị vào `docs`.
- Chuyển project bán lẻ tham khảo vào `references/retail-management` và đánh dấu chỉ dùng tham khảo.

### Preserved

- Backend mục tiêu tiếp tục dùng Spring Boot.
- Database mục tiêu tiếp tục dùng Microsoft SQL Server.
- Frontend Vanilla JavaScript đang chạy được giữ nguyên làm baseline.
