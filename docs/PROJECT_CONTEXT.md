# Project context - BlueStock

Tài liệu này là điểm vào ngắn nhất cho thành viên hoặc công cụ hỗ trợ cần hiểu repository trước khi build. Nội dung chi tiết vẫn nằm trong các tài liệu nguồn được liên kết bên dưới.

## Mục tiêu sản phẩm

BlueStock là hệ thống quản lý kho phục vụ đồ án DBMS330284. Hệ thống phải demo được luồng từ danh mục và vị trí lưu trữ đến nhập lô, xem tồn, xuất FEFO, chuyển kho, kiểm kê, trả hàng, báo cáo và audit.

Bốn vai trò dự kiến:

- `Admin`: quản trị nhân viên, tài khoản, role và danh mục.
- `QuanLyKho`: quản lý cấu trúc kho, duyệt chứng từ và xem báo cáo.
- `NhanVienKho`: lập và thao tác chứng từ kho trong phạm vi được cấp.
- `KeToan`: xem chứng từ, giá trị nhập-xuất-tồn và báo cáo; không trực tiếp sửa tồn.

## Hiện trạng repository

| Thành phần | Hiện trạng | Nguồn |
| --- | --- | --- |
| Frontend | Baseline HTML/CSS/Vanilla JavaScript chạy bằng static server, đang dùng dữ liệu demo | [`../apps/web/README.md`](../apps/web/README.md) |
| Backend | Có Spring Boot/Maven Wrapper, health/session API, CRUD danh mục/đối tác/cấu trúc kho, nhập/xuất/chuyển/kiểm kê/trả hàng, tra cứu tồn và báo cáo nhập–xuất–tồn/chênh lệch kiểm kê; audit và một số báo cáo chưa có | [`../services/api/README.md`](../services/api/README.md) |
| Database | Có `init.sql` dựng 26 bảng gồm sổ biến động tồn, năm procedure hoàn tất nhập/xuất/chuyển/kiểm kê/trả và các view tồn/báo cáo; audit và một số object rubric chưa có | [`../database/README.md`](../database/README.md) |
| API contract | Baseline Draft; contract session và danh mục sản phẩm đã chốt cho nhánh BE, nghiệp vụ kho còn thiếu | [`../contracts/BASELINE.md`](../contracts/BASELINE.md) |
| Phân công | Có đề xuất bốn workstream, còn chờ nhóm xác nhận | [`project/governance/WORKSTREAMS.md`](project/governance/WORKSTREAMS.md) |

Không mô tả phần chưa được tạo như thể đã chạy được. Khi hiện trạng thay đổi, cập nhật bảng này trong cùng PR.

## Công nghệ đã chốt

- Frontend baseline: HTML5, CSS3, Vanilla JavaScript.
- Backend: Java 21, Spring Boot 3.x, Spring Web, Spring Security.
- Persistence: Spring Data JPA cho CRUD phù hợp; Spring JDBC/JdbcTemplate cho procedure/function quan trọng.
- Database: Microsoft SQL Server 2022 và T-SQL.
- Giao tiếp: JSON qua HTTP.
- Mô hình triển khai: monorepo, backend modular monolith, package-by-feature.

Không đổi backend sang Node/PostgreSQL hoặc đổi framework frontend nếu chưa có backlog và ADR được chấp nhận.

## Luồng nghiệp vụ quan trọng nhất

```text
Danh mục + cấu trúc kho
          │
          ▼
Lập phiếu nhập → hoàn tất → tạo lô → put-away → tăng tồn
                                                   │
                                                   ▼
                                      tra cứu tồn theo lô/vị trí
                                                   │
                                                   ▼
Lập phiếu xuất → gợi ý FEFO → hoàn tất → trừ tồn → báo cáo
                                                   │
                       ┌───────────────────────────┼──────────────┐
                       ▼                           ▼              ▼
                  chuyển kho                   kiểm kê        trả hàng
```

Luồng E2E tối thiểu để bảo vệ là: đăng nhập → nhập lô → xem tồn → xuất FEFO → xem báo cáo, kèm ít nhất một lỗi rollback.

## Invariant không được phá vỡ

- Tồn kho là số lượng theo cặp `(MaViTri, MaLo)`, không phải một số tổng do frontend giữ.
- Tồn không âm; đọc-kiểm tra-cập nhật tồn phải nằm trong transaction và khóa đúng dữ liệu.
- Chứng từ chỉ ghi sổ một lần; gọi hoàn tất lần hai phải thất bại mà không đổi tồn.
- Chỉ chứng từ nháp được sửa/xóa. Chứng từ hoàn tất phải dùng nghiệp vụ đảo/điều chỉnh.
- Xuất chỉ lấy lô còn hạn và ưu tiên FEFO.
- Chuyển kho giảm nguồn/tăng đích nguyên tử và không vượt sức chứa.
- Trả hàng cộng dồn không vượt lượng đã xuất.
- Mật khẩu chỉ lưu dạng hash; backend/database là nguồn sự thật về quyền.

Danh sách có mã kiểm thử nằm trong [`requirements/BUSINESS_RULES.md`](requirements/BUSINESS_RULES.md).

## Kiến trúc và ranh giới

- Controller chỉ xử lý HTTP/DTO và gọi application service.
- Application service là transaction/use-case boundary phía Java.
- Module khác chỉ import public interface/DTO; không import repository, JPA entity hoặc implementation nội bộ.
- Nghiệp vụ ghi sổ quan trọng gọi stored procedure hoặc adapter transaction đã được kiểm thử; không viết một bản logic tồn ở frontend.
- API/schema thay đổi phải cập nhật contract, script, test và tài liệu cùng thay đổi.

Xem [`architecture/SYSTEM_ARCHITECTURE.md`](architecture/SYSTEM_ARCHITECTURE.md) và [`architecture/MODULE_CATALOG.md`](architecture/MODULE_CATALOG.md).

## Nguồn sự thật

Khi có mâu thuẫn, dùng thứ tự sau:

1. Quyết định hiện tại, rõ ràng của Project Owner/nhóm.
2. `AGENTS.md` gần file đang sửa.
3. Backlog và ADR hiện hành.
4. ERD, yêu cầu và contract đã được review.
5. Code/test đã tích hợp.
6. Tài liệu tham khảo hoặc lịch sử.

Tài liệu có nhãn `Draft`, `Cần chốt` hoặc `Proposed` không được xem là quyết định đã Accepted.

## Đường đọc theo công việc

| Khi làm việc | Đọc tối thiểu |
| --- | --- |
| Khởi tạo/chạy toàn hệ thống | [`development/BUILD_GUIDE.md`](development/BUILD_GUIDE.md), [`architecture/SYSTEM_ARCHITECTURE.md`](architecture/SYSTEM_ARCHITECTURE.md) |
| Sửa database | [`../database/AGENTS.md`](../database/AGENTS.md), [`../database/SCHEMA_PLAN.md`](../database/SCHEMA_PLAN.md), ERD |
| Sửa backend | [`../services/api/AGENTS.md`](../services/api/AGENTS.md), module catalog, API catalog |
| Sửa frontend | [`../apps/web/AGENTS.md`](../apps/web/AGENTS.md), API catalog, contract của resource |
| Làm transaction kho | Business rules, ERD, contract procedure và test strategy |
| Chia việc/merge | Workstreams, TEAM, backlog và tài liệu quyết định còn mở |

## Các quyết định triển khai

Quy ước URL, xác thực, thời gian, precision tiền, sinh mã, trạng thái chứng từ và mã lỗi procedure đã được chốt cho nhánh BE tại [`architecture/adr/0003-be-platform-contract.md`](architecture/adr/0003-be-platform-contract.md). Quy tắc tồn kho nằm tại [`architecture/adr/0004-stock-policies.md`](architecture/adr/0004-stock-policies.md). Các quyết định tích hợp còn mở được theo dõi trong [`project/governance/OPEN_DECISIONS.md`](project/governance/OPEN_DECISIONS.md).

## Lệnh hiện dùng được

```powershell
pwsh -File scripts/setup.ps1
pwsh -File scripts/dev.ps1 -Target web
pwsh -File scripts/verify.ps1
```

Backend hiện có thể chạy khi cấu hình kết nối SQL Server theo `services/api/README.md`; database mới dựng được identity, danh mục và cấu trúc kho bằng `database/init.sql`.
