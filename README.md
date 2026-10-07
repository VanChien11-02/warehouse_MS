# Hệ thống quản lý kho hàng

Đồ án cuối kỳ môn Hệ quản trị cơ sở dữ liệu (DBMS330284). Hệ thống quản lý danh mục hàng hóa, nhập kho, xuất kho, tồn theo lô và vị trí, chuyển kho, kiểm kê, trả hàng, báo cáo và nhật ký thao tác.

## Trạng thái hiện tại

- Frontend baseline có dashboard, form chứng từ và báo cáo bằng dữ liệu mẫu; chế độ API hiện hỗ trợ CRUD sản phẩm và tra cứu tồn kho.
- Backend có session/RBAC, quản trị tài khoản, CRUD danh mục/kho/đối tác, năm luồng chứng từ, tra cứu tồn, báo cáo và audit.
- `database/init.sql` dựng 27 bảng, năm procedure hoàn tất chứng từ, năm function, bảy view, trigger, index và bốn database role. Seed demo tách khỏi schema và không chứa tài khoản hay mật khẩu.
- Các test Java, SQL và tranh chấp hai session đã chạy trên SQL Server 2025 Express; kết nối JDBC/HTTP với SQL Server local và SQL Server 2022 còn cần kiểm chứng.
- Thư mục `references/` chỉ dùng tham khảo cách tổ chức; không phải nguồn yêu cầu của dự án này.

## Công nghệ thống nhất

| Thành phần | Công nghệ |
| --- | --- |
| Frontend hiện tại | HTML5, CSS3, Vanilla JavaScript, Fetch API |
| Frontend mục tiêu | Giữ baseline hiện tại; chỉ chuyển Vue 3 + TypeScript + Vite qua backlog riêng nếu nhóm chấp nhận |
| Backend | Java 21 LTS, Spring Boot 3.x, Spring Web, Spring Security, Spring JDBC/JPA |
| Database | Microsoft SQL Server 2022, T-SQL |
| Công cụ | Git, PowerShell 7, Node.js 22 LTS, SSMS hoặc Azure Data Studio |

Spring Boot và SQL Server là quyết định cố định. Logic ghi sổ tồn kho quan trọng phải được bảo vệ bằng transaction ở database/backend; frontend không tự tính và ghi tồn kho như nguồn sự thật.

## Bắt đầu nhanh

### 1. Chuẩn bị môi trường

Cài đặt:

- Git 2.40 trở lên.
- PowerShell 7.
- Node.js 22 LTS hoặc mới hơn; CI tương lai sẽ chốt Node.js 22.
- JDK 21 hoặc mới hơn, với `JAVA_HOME` trỏ tới JDK; mã nguồn backend nhắm Java 21.
- SQL Server 2022 Developer/Express và công cụ quản trị SQL.

### 2. Clone và tạo nhánh

```powershell
git clone <repository-url>
cd <repository-folder>
git switch main
git pull
git switch -c feature/<issue>-<ket-qua>
```

Không commit trực tiếp lên `main`.

Khi nhóm chấp nhận mô hình bốn workstream, owner tạo `workstream/<pham-vi>` từ cùng commit contract baseline thay cho branch feature ban đầu. Xem [kế hoạch phát triển song song](docs/project/governance/WORKSTREAMS.md).

### 3. Thiết lập và chạy

```powershell
pwsh -File scripts/setup.ps1
sqlcmd -S localhost -E -C -b -i database/init.sql
sqlcmd -S localhost -E -C -b -d BlueStock -i database/seed/demo.sql
```

Sau khi bật TCP/IP cho SQL Server và cấu hình JDBC theo [hướng dẫn build](docs/development/BUILD_GUIDE.md), tạo Admin một lần. Lệnh bootstrap sẽ khởi động API; dừng tiến trình đó rồi chạy API bình thường:

```powershell
pwsh -File scripts/bootstrap-admin.ps1
pwsh -File scripts/dev.ps1 -Target api
```

Chạy `pwsh -File scripts/dev.ps1 -Target web` ở terminal khác và mở `http://127.0.0.1:5174`. Frontend hiện dùng dữ liệu mẫu; dùng API theo [`services/api/README.md`](services/api/README.md) để thử nghiệp vụ thật.

### 4. Kiểm tra trước khi bàn giao

```powershell
pwsh -File scripts/verify.ps1
pwsh -File scripts/verify.ps1 -WithDatabase -WithConcurrency
```

## Cấu trúc repository

```text
apps/
  web/                       Frontend quản lý kho
services/
  api/                       Spring Boot API theo module nghiệp vụ
database/                    Schema, procedure, function, trigger, view, index, seed và test SQL Server
contracts/                   Hợp đồng API/DTO liên frontend-backend
docs/
  architecture/              ERD, quyết định kiến trúc và thiết kế database
  project/governance/        Backlog, phân công và quy trình nhóm
  reference/                 PDF đề bài và tài liệu nguồn
  testing/                   Kế hoạch, traceability và kết quả test
scripts/                     Lệnh setup, chạy local và kiểm tra
.github/                     Issue/PR template và CI
references/                  Project khác dùng tham khảo, không sửa theo nghiệp vụ kho
```

## Tài liệu cần đọc trước khi sửa code

1. [`AGENTS.md`](AGENTS.md).
2. [`docs/README.md`](docs/README.md).
3. [`docs/PROJECT_CONTEXT.md`](docs/PROJECT_CONTEXT.md).
4. Backlog item liên quan trong [`docs/project/governance/BACKLOG.md`](docs/project/governance/BACKLOG.md).
5. `AGENTS.md` gần nhất trong module sẽ sửa, nếu có.
6. ERD, business rules và contract liên quan.

## Nguồn sự thật

Khi tài liệu mâu thuẫn, ưu tiên theo thứ tự:

1. Quyết định hiện tại của nhóm/Project Owner.
2. `AGENTS.md` gần file đang sửa.
3. Backlog và quyết định kiến trúc hiện hành.
4. ERD, yêu cầu và API contract đã được review.
5. Code và test đã tích hợp.
6. Tài liệu tham khảo hoặc lịch sử.

## Liên kết chính

- [Bản đồ tài liệu](docs/README.md)
- [Project context](docs/PROJECT_CONTEXT.md)
- [Hướng dẫn build](docs/development/BUILD_GUIDE.md)
- [Hướng dẫn đóng góp](CONTRIBUTING.md)
- [Backlog](docs/project/governance/BACKLOG.md)
- [Phân công nhóm](docs/project/governance/TEAM.md)
- [Kế hoạch bốn workstream phát triển song song](docs/project/governance/WORKSTREAMS.md)
- [Draft contract baseline liên module](contracts/BASELINE.md)
- [Danh mục API dự kiến](contracts/API_CATALOG.md)
- [Các quyết định còn mở](docs/project/governance/OPEN_DECISIONS.md)
- [ERD và nghiệp vụ](docs/architecture/database/ERD_VA_NGHIEP_VU.md)
- [Changelog](CHANGELOG.md)
