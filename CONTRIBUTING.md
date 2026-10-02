# Hướng dẫn đóng góp

## Chuẩn bị

1. Cài Git, PowerShell 7, Node.js 22 LTS, JDK 21 và SQL Server 2022.
2. Clone repository và tạo nhánh từ `main`.
3. Chạy `pwsh -File scripts/setup.ps1`.
4. Đọc [`README.md`](README.md), [`docs/README.md`](docs/README.md), backlog item và `AGENTS.md` gần phần mã sẽ sửa.

## Quy trình

1. Mỗi thay đổi phải có Issue/backlog item với kết quả cần tạo, owner, reviewer, phụ thuộc và tiêu chí chấp nhận.
2. Mỗi người chỉ giữ tối đa một việc `In Progress`.
3. Dùng tên nhánh:
   - `feature/<issue>-<ket-qua>`
   - `fix/<issue>-<van-de>`
   - `docs/<issue>-<noi-dung>`
   - `test/<issue>-<pham-vi>`
4. Mở Draft PR sớm khi cần thống nhất contract hoặc schema.
5. Thay đổi API/database phải có reviewer của cả phía cung cấp và phía sử dụng.
6. Chỉ merge khi kiểm tra đạt, reviewer chấp thuận và tài liệu liên quan đã cập nhật.

Khuyến nghị Conventional Commits: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:` và `ci:`.

## Cổng chất lượng

```powershell
pwsh -File scripts/verify.ps1
```

Nếu một kiểm tra chưa chạy được, ghi chính xác lệnh, nguyên nhân và rủi ro trong PR.

## Git an toàn

- Không commit trực tiếp lên `main`.
- Không force-push nhánh dùng chung.
- Không sửa hoặc xóa thay đổi chưa commit của người khác.
- Không commit `.env`, secret, connection string thật, database backup, build output, test artifact, `.idea`, `.vscode`, `.agents` hoặc `.codex`.
- Trước khi xóa nhánh, xác nhận commit cần giữ đã nằm trên `main` hoặc nhánh lưu trữ.
