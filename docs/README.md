# Bản đồ tài liệu

Tài liệu trong `docs/` là nguồn hiện hành của dự án quản lý kho. Nội dung trong `references/` chỉ dùng tham khảo cách tổ chức và không được tự động xem là yêu cầu nghiệp vụ.

## Bắt đầu build

- [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md): briefing ngắn về mục tiêu, hiện trạng, invariant, nguồn sự thật và đường đọc theo công việc.
- [`development/BUILD_GUIDE.md`](development/BUILD_GUIDE.md): môi trường, lệnh đang chạy được, thứ tự kỹ thuật và checklist build sạch.
- [`project/governance/OPEN_DECISIONS.md`](project/governance/OPEN_DECISIONS.md): các điểm chưa được phép tự suy đoán trên từng branch.

## Kiến trúc và dữ liệu

- [`architecture/database/ERD_VA_NGHIEP_VU.md`](architecture/database/ERD_VA_NGHIEP_VU.md): ERD, quy tắc dữ liệu và danh sách nghiệp vụ.
- [`architecture/database/PHYSICAL_SCHEMA.md`](architecture/database/PHYSICAL_SCHEMA.md): kiểu dữ liệu và ràng buộc của các bảng đã triển khai.
- [`architecture/database/mermaid-diagram.png`](architecture/database/mermaid-diagram.png): ảnh ERD tham khảo hiện tại.
- [`architecture/SYSTEM_ARCHITECTURE.md`](architecture/SYSTEM_ARCHITECTURE.md): luồng frontend/API/database, transaction và nguồn sự thật.
- [`architecture/MODULE_CATALOG.md`](architecture/MODULE_CATALOG.md): ownership kỹ thuật, dependency và public surface của từng module.
- [`architecture/adr/0001-repository-layout.md`](architecture/adr/0001-repository-layout.md): quyết định cấu trúc repository.
- [`architecture/adr/0002-technology-stack.md`](architecture/adr/0002-technology-stack.md): quyết định công nghệ frontend/backend/database.
- [`architecture/adr/0003-be-platform-contract.md`](architecture/adr/0003-be-platform-contract.md): quy ước nền tảng đã chốt cho nhánh triển khai backend.
- [`architecture/adr/0004-stock-policies.md`](architecture/adr/0004-stock-policies.md): quy tắc ghi sổ và định giá tồn kho cho nhánh triển khai backend.
- [`architecture/adr/0005-outbound-fefo-enforcement.md`](architecture/adr/0005-outbound-fefo-enforcement.md): kiểm tra thứ tự FEFO tại transaction hoàn tất xuất.
- [`architecture/adr/0006-transfer-posting.md`](architecture/adr/0006-transfer-posting.md): khóa và ghi sổ chuyển kho.

## Quản lý dự án

- [`project/governance/BACKLOG.md`](project/governance/BACKLOG.md): phạm vi, ưu tiên và phụ thuộc.
- [`project/governance/TEAM.md`](project/governance/TEAM.md): phân công hiện tại theo rubric và module.
- [`project/governance/WORKSTREAMS.md`](project/governance/WORKSTREAMS.md): đề xuất chia bốn workstream, branch, ranh giới file và baseline để phát triển song song.
- [`project/governance/SCRUM.md`](project/governance/SCRUM.md): Ready, Done, nhánh và Pull Request.

GitHub Issues/Project giữ trạng thái làm việc hằng ngày. Backlog Markdown chỉ giữ phạm vi, ưu tiên và quan hệ phụ thuộc để không phải cập nhật trạng thái ở hai nơi.

## Kiểm thử

- [`testing/README.md`](testing/README.md): chiến lược test và bằng chứng cần lưu.
- [`testing/CONCURRENCY.md`](testing/CONCURRENCY.md): kịch bản hai session xuất cạnh tranh cùng tồn.
- [`testing/API_SMOKE.md`](testing/API_SMOKE.md): kịch bản Postman nhập → tồn → xuất FEFO → báo cáo trên dữ liệu demo.
- [`testing/LOCAL_EVIDENCE.md`](testing/LOCAL_EVIDENCE.md): lệnh, kết quả và giới hạn kiểm chứng local gần nhất.

## Yêu cầu và hợp đồng

- [`requirements/BUSINESS_RULES.md`](requirements/BUSINESS_RULES.md): quy tắc nghiệp vụ có mã `BR-*` để liên kết với contract/code/test.
- [`../contracts/BASELINE.md`](../contracts/BASELINE.md): quy ước contract chung đang ở trạng thái Draft.
- [`../contracts/API_CATALOG.md`](../contracts/API_CATALOG.md): inventory endpoint dự kiến và thứ tự viết contract chi tiết.
- [`../contracts/session-rbac.md`](../contracts/session-rbac.md): session, CSRF, payload đăng nhập và mã role cho nhánh BE.
- [`../contracts/identity-admin.md`](../contracts/identity-admin.md): quản trị nhân viên, tài khoản, role và reset mật khẩu.
- [`../contracts/audit.md`](../contracts/audit.md): bảng và API nhật ký thao tác.
- [`../contracts/san-pham.md`](../contracts/san-pham.md): CRUD, tìm kiếm, phân trang và quyền của sản phẩm.
- [`../contracts/loai-don-vi-tinh.md`](../contracts/loai-don-vi-tinh.md): CRUD, tìm kiếm và quyền của loại sản phẩm và đơn vị tính.
- [`../contracts/warehouse-location.md`](../contracts/warehouse-location.md): CRUD và quyền của cấu trúc kho.
- [`../contracts/partner.md`](../contracts/partner.md): schema nhà cung cấp, đối tác nhận và mapping sản phẩm.
- [`../contracts/inbound-completion.md`](../contracts/inbound-completion.md): schema, procedure và API tạo/xem/hoàn tất nhập.
- [`../contracts/inventory-query.md`](../contracts/inventory-query.md): tra cứu tồn khả dụng theo lô/vị trí và nguồn giá nhập.
- [`../contracts/outbound-fefo-completion.md`](../contracts/outbound-fefo-completion.md): schema, procedure và API tạo/xem/hoàn tất xuất.
- [`../contracts/reporting.md`](../contracts/reporting.md): báo cáo nhập–xuất–tồn theo kỳ và kho/sản phẩm.
- [`../contracts/expiry-report.md`](../contracts/expiry-report.md): báo cáo lô sắp hết hạn theo tồn khả dụng.
- [`../contracts/transfer.md`](../contracts/transfer.md): schema phiếu chuyển vị trí và quy tắc ghi sổ.
- [`../database/SCHEMA_PLAN.md`](../database/SCHEMA_PLAN.md): kế hoạch physical schema, object SQL và test database.

## Tài liệu nguồn

- [`reference/README.md`](reference/README.md): quy tắc lưu và sử dụng tài liệu nguồn.
- Hai PDF thiết kế ban đầu/rubric được mô tả trong lịch sử dự án nhưng hiện không có trong checkout. Khi nhóm bổ sung lại, cần dùng tên ổn định, không sửa trực tiếp PDF và cập nhật liên kết tại đây.

## Khi tài liệu mâu thuẫn

Ưu tiên quyết định mới nhất của nhóm, `AGENTS.md` gần phạm vi sửa, backlog/ADR hiện hành, ERD/contract đã review, code/test đã tích hợp, sau cùng mới đến tài liệu tham khảo.

Không sửa tài liệu nguồn PDF hoặc project tham khảo để làm như thể quyết định cũ chưa từng tồn tại. Ghi quyết định mới bằng ADR/backlog và cập nhật liên kết từ tài liệu hiện hành.
