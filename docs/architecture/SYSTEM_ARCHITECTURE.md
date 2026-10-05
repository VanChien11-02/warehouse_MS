# Kiến trúc hệ thống BlueStock

- Trạng thái: **Baseline architecture**.
- Các lựa chọn chưa chốt được liên kết tới [`../project/governance/OPEN_DECISIONS.md`](../project/governance/OPEN_DECISIONS.md).

## Sơ đồ tổng thể

```text
┌──────────────────────────┐
│ Browser                  │
│ HTML/CSS/Vanilla JS      │
└─────────────┬────────────┘
              │ JSON/HTTP
              ▼
┌──────────────────────────┐
│ Spring Boot API          │
│ Controller + DTO         │
│ Application services     │
│ Domain rules             │
│ JPA/JDBC adapters        │
└─────────────┬────────────┘
              │ JDBC/T-SQL
              ▼
┌──────────────────────────┐
│ Microsoft SQL Server     │
│ Tables + constraints     │
│ Procedures/functions     │
│ Triggers/views/indexes   │
│ Roles and permissions    │
└──────────────────────────┘
```

## Nguồn sự thật theo loại dữ liệu

| Nội dung | Nguồn sự thật | Không được dùng làm nguồn sự thật |
| --- | --- | --- |
| Quyền thực thi | Spring Security và quyền SQL phù hợp | Ẩn/hiện menu frontend |
| Tồn cuối cùng | SQL Server sau transaction hoàn tất | Tổng tạm tính trên trình duyệt |
| Trạng thái chứng từ | Backend/database | Giá trị DOM hoặc local storage |
| API payload | Contract đã Accepted | JPA entity hoặc object demo |
| Quy tắc nghiệp vụ | Business rules + code/test tích hợp | Project trong `references/` |

## Backend modular monolith

Mỗi feature dùng cấu trúc theo nhu cầu:

```text
<feature>/
├─ api/              controller, request/response, public port
├─ application/      use case, orchestration, transaction boundary
├─ domain/           entity/value object/rule không phụ thuộc HTTP/JPA
└─ infrastructure/   JPA, JDBC, security và adapter bên ngoài
```

Không bắt buộc tạo đủ bốn package nếu feature rất nhỏ. Tuy nhiên dependency phải hướng từ adapter vào application/domain; domain không phụ thuộc controller, JPA entity hoặc JSON.

## Quy tắc dependency module

```text
auth ─────────────────────────────────────────────────┐
catalog ─────┬─> inbound ──> inventory ──> reporting │
partner ─────┤       │            ▲                  │
warehouse ───┘       └────────────┼─> outbound ──────┤
                                 ├─> transfer        │
                                 ├─> inventorycount  │
                                 └─> returning       │
audit <──────────────────── các use case quan trọng ──┘
```

- `auth` cung cấp principal/role; feature khác không đọc bảng tài khoản trực tiếp.
- `catalog`, `partner` và `warehouse` cung cấp snapshot/query port cho mã sản phẩm, đối tác và vị trí.
- `inventory` cung cấp truy vấn tồn; các nghiệp vụ ghi sổ có procedure/use case riêng, không dùng một hàm `setStock()` chung.
- `reporting` chỉ đọc view/query model; không sửa tồn.
- `audit` nhận dữ liệu từ use case hoặc trigger được thiết kế rõ, không ghi dữ liệu nhạy cảm.

## Luồng request chuẩn

```text
HTTP request
  → authentication/authorization
  → request DTO validation
  → application use case
  → domain/business validation
  → repository hoặc JDBC procedure adapter
  → commit/rollback
  → response DTO hoặc lỗi có cấu trúc
```

Controller không gọi repository trực tiếp. Không trả JPA entity ra API. Lỗi SQL phải được ánh xạ thành mã lỗi ổn định, không lộ stack trace hoặc câu SQL.

## Transaction và stored procedure

Các use case hoàn tất phiếu nhập, xuất, chuyển, kiểm kê và trả hàng là transaction nghiệp vụ. Procedure tương ứng phải:

- dùng `SET XACT_ABORT ON` và `TRY...CATCH`;
- kiểm tra trạng thái trong cùng transaction;
- chống hoàn tất cùng chứng từ hai lần;
- khóa dữ liệu tồn trước bước đọc-kiểm tra-cập nhật;
- rollback toàn bộ nếu bất kỳ bước nào thất bại;
- trả kết quả/mã lỗi theo contract đã chốt.

Không chia một lần ghi sổ thành nhiều HTTP request phụ thuộc trình duyệt để hoàn thành transaction.

## Frontend

Frontend hiện là static baseline. Cấu trúc mục tiêu sau `GOV-03`:

```text
apps/web/
├─ src/core/                    router, session, API client, error handling
├─ src/features/auth/
├─ src/features/master-data/
├─ src/features/inbound-inventory/
├─ src/features/outbound-control/
└─ styles/                      tokens, components, feature styles
```

Mỗi feature gọi API qua adapter tập trung, có loading/empty/error/success state và không chứa secret hoặc logic quyết định tồn cuối cùng.

## Database

- Schema vật lý bám ERD hiện hành.
- Một object chính trên một file; `init.sql` chỉ điều phối thứ tự.
- Procedure/view/function/trigger nên dùng `CREATE OR ALTER` khi SQL Server hỗ trợ.
- Script baseline dựng từ database sạch; chiến lược migration sau baseline chưa được chốt.
- Seed chỉ chứa dữ liệu demo giả, đủ cho E2E và rubric.

Thứ tự object và ownership nằm tại [`../../database/SCHEMA_PLAN.md`](../../database/SCHEMA_PLAN.md).

## Bảo mật

- Mật khẩu hash bằng cơ chế phù hợp của Spring Security; thuật toán/parameters cần được chốt khi làm `SEC-01`.
- Mặc định từ chối endpoint chưa khai báo quyền.
- Không log password, token, connection string hoặc payload nhạy cảm.
- SQL login/user/role phục vụ rubric phải tách khỏi secret ứng dụng được commit.
- Frontend role switch hiện tại chỉ là demo presentation, không phải authorization.

## Khả năng quan sát và lỗi

Mỗi lỗi API có `code`, `message`, `fieldErrors` và `traceId` theo baseline contract. Log server cần đủ `traceId`, use case và actor để điều tra nhưng không chứa secret.

## Triển khai hiện tại

Chưa có container/deployment production được chấp nhận. Mục tiêu trước mắt là local demo trên Windows với frontend port `5174`, API dự kiến `8080` và SQL Server 2022. Không bổ sung Docker/cloud như yêu cầu bắt buộc nếu chưa có backlog/ADR.
