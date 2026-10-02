# Hướng dẫn làm việc trong repository

## Mục tiêu

Xây dựng hệ thống quản lý kho kết nối Spring Boot và SQL Server, có thể demo trực tiếp, đáp ứng rubric môn DBMS330284 và cho phép bốn thành viên phát triển song song.

Trước khi thay đổi file, phải đọc `docs/README.md`, backlog item liên quan và `AGENTS.md` gần nhất trong phạm vi module.

## Nguồn sự thật

Giải quyết mâu thuẫn theo thứ tự:

1. Quyết định hiện tại, rõ ràng của Project Owner/nhóm.
2. `AGENTS.md` gần file đang sửa.
3. Backlog sprint và ADR hiện hành.
4. ERD, yêu cầu, API contract đã được review.
5. Code và test đã tích hợp.
6. Tài liệu trong `references/` hoặc tài liệu lịch sử.

Không chép nguyên quyết định nghiệp vụ, tên bảng, role hoặc công nghệ từ project tham khảo sang dự án kho.

## Ràng buộc công nghệ

- Backend giữ Java 21 + Spring Boot 3.x.
- Database giữ Microsoft SQL Server và T-SQL.
- Frontend baseline hiện là HTML/CSS/Vanilla JavaScript. Chỉ đổi framework qua backlog/ADR riêng và phải giữ đủ hành vi đang chạy.
- API dùng JSON qua HTTP; hợp đồng dùng chung nằm trong `contracts/`.
- Không lưu mật khẩu rõ, secret, connection string thật, file `.bak`, `node_modules`, build output hoặc cấu hình IDE trong Git.

## Cấu trúc

- `apps/web/`: frontend.
- `services/api/`: Spring Boot modular monolith, package-by-feature.
- `database/`: các đối tượng SQL Server phục vụ rubric và script khởi tạo.
- `contracts/`: hợp đồng API liên module.
- `docs/`: tài liệu hiện hành.
- `scripts/`: lệnh setup/dev/verify.
- `references/`: chỉ đọc để tham khảo cách tổ chức.

## Quy tắc phát triển

- Controller không gọi repository trực tiếp; application service là transaction boundary.
- Không để frontend tự quyết định số tồn cuối cùng, quyền truy cập hoặc trạng thái hoàn tất chứng từ.
- Stored procedure nghiệp vụ phải có `TRY...CATCH`, transaction và cơ chế chống ghi sổ hai lần.
- Không sửa/xóa chứng từ đã hoàn tất; sử dụng chứng từ đảo/điều chỉnh theo thiết kế.
- Mỗi thay đổi API/schema phải cập nhật contract, migration/script, test và tài liệu liên quan trong cùng PR.
- Giữ PR nhỏ, có owner, reviewer và acceptance criteria.

## Kiểm chứng

Từ root repository chạy:

```powershell
pwsh -File scripts/verify.ps1
```

Chạy kiểm tra hẹp trong lúc làm, nhưng phải chạy cổng đầy đủ trước khi bàn giao. Không ghi “đã test” nếu không có lệnh và kết quả cụ thể.

## Handoff

Khi bàn giao, nêu rõ:

- File/module đã đổi.
- Lệnh kiểm tra đã chạy và kết quả.
- Phần chưa chạy được cùng lý do.
- Rủi ro hoặc quyết định còn chờ nhóm chốt.
