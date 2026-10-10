# SQL Server database

Thư mục này chứa toàn bộ script T-SQL có thể dựng lại database từ đầu và các đối tượng phục vụ rubric.

Hiện `init.sql` tạo chín bảng nền tảng cho identity, danh mục sản phẩm và cấu trúc kho. Bốn role ứng dụng được seed; chưa có tài khoản. Các bảng chứng từ, tồn kho và dữ liệu mẫu sẽ được bổ sung theo từng module.

## Chạy schema nền tảng

Từ thư mục gốc repository, dùng SQL Server có Windows Authentication và `sqlcmd`:

```powershell
sqlcmd -S localhost -E -C -b -i database/init.sql
pwsh -File scripts/verify.ps1 -WithDatabase
```

`init.sql` tạo database `BlueStock` và dừng nếu tên này đã tồn tại; script không xóa hoặc ghi đè database cũ. Khi dùng SQL Server ở máy khác, thay `localhost` bằng tên instance tương ứng.

## Cấu trúc mục tiêu

```text
database/
  schema/                 Bảng, PK, FK, CHECK, UNIQUE, DEFAULT
  programmability/
    procedures/           Stored procedure
    functions/            User-defined function
    triggers/             Trigger
    views/                View
  indexes/                Index và script đo hiệu năng
  security/               Login, user, role, GRANT/REVOKE/DENY
  seed/                   Dữ liệu demo
  tests/                  Script kiểm tra constraint, transaction và concurrency
  init.sql                Điểm vào chạy theo đúng thứ tự
```

## Quy tắc

- Script phải chạy được trên SQL Server 2022 từ database sạch.
- Mỗi bảng dùng khóa/ràng buộc theo ERD hiện hành.
- Năm nghiệp vụ hoàn tất chứng từ phải có transaction, `TRY...CATCH` và rollback.
- Không commit file `.bak`, `.mdf`, `.ldf` hoặc dữ liệu thật.
- Mọi object phải có mục đích nghiệp vụ, không tạo chỉ để đủ số lượng rubric.

Thiết kế hiện hành: [`../docs/architecture/database/ERD_VA_NGHIEP_VU.md`](../docs/architecture/database/ERD_VA_NGHIEP_VU.md).

Kế hoạch physical schema, thứ tự object, ownership và checklist DB-01: [`SCHEMA_PLAN.md`](SCHEMA_PLAN.md).
