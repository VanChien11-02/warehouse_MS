# SQL Server database

Thư mục này chứa toàn bộ script T-SQL có thể dựng lại database từ đầu và các đối tượng phục vụ rubric.

Để dựng SQL Server 2022 và API/web bằng Compose trên máy hỗ trợ Docker, xem [`../docs/development/DOCKER_DEMO.md`](../docs/development/DOCKER_DEMO.md). Cách chạy `sqlcmd -E` bên dưới dành cho SQL Server cài trực tiếp trên Windows.

`init.sql` tạo 28 bảng, năm procedure hoàn tất chứng từ, năm function, bảy view, năm trigger bảo vệ bất biến kho, index tra cứu và bốn role SQL. Bốn role ứng dụng được seed trong bảng `ROLE`; chưa có tài khoản đăng nhập. Script dựng mới không tạo dữ liệu demo hoặc mật khẩu.

Quyết định ACC-01 bổ sung bảng `DOI_SOAT_GIA_TRI` (28 bảng) cho Kế toán đối
soát giá trị phiếu nhập/xuất đã hoàn tất. Database hiện có chạy một lần
`sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/028_accounting_reconciliation.sql`.
Migration cũng đồng bộ quyền SQL với chính sách vai trò ngày 2026-10-22;
database dựng mới đã chứa bảng và quyền này qua `init.sql`.

## Chạy schema nền tảng

Từ thư mục gốc repository, dùng SQL Server có Windows Authentication và `sqlcmd`:

```powershell
sqlcmd -S localhost -E -C -b -i database/init.sql
pwsh -File scripts/verify.ps1 -WithDatabase
```

Nếu kiểm tra một database dựng mới với tên riêng, truyền
`-DatabaseName <ten_database>` cho `scripts/verify.ps1`; mặc định là `BlueStock`.
Các bài test SQL tạo và dọn dữ liệu giả trong database được chỉ định.

`init.sql` tạo database `BlueStock` và dừng nếu tên này đã tồn tại; script không xóa hoặc ghi đè database cũ. Khi dùng SQL Server ở máy khác, thay `localhost` bằng tên instance tương ứng.

Sau khi dựng schema, chạy `sqlcmd -S localhost -E -C -b -d BlueStock -i database/seed/demo.sql` để tạo danh mục, đối tác, kho/vị trí và ba lô mẫu phục vụ luồng FEFO. Seed dùng dữ liệu giả, không tạo tài khoản hoặc mật khẩu và có thể chạy lại. Xem [`seed/README.md`](seed/README.md). Nếu chỉ thử CRUD sản phẩm, dùng `database/seed/catalog_demo.sql` để tạo loại/đơn vị tính mà chưa tạo sản phẩm.

Nếu database local đã được dựng từ commit trước khi có đối tác, chạy một lần `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/001_partner.sql`. Migration này chỉ thêm bốn bảng, dừng nếu đã chạy hoặc có bảng dở dang; không xóa dữ liệu cũ. Database dựng mới bằng `init.sql` đã có bốn bảng này và không chạy migration.

Sau migration đối tác, database local cũ cần chạy tiếp một lần `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/002_inbound_inventory.sql`. Migration này thêm phiếu nhập, dòng nhập, lô, tồn và hai sequence; chưa có procedure ghi sổ. Database dựng mới bằng `init.sql` đã có các object này.

Sau migration 002, chạy `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/003_inbound_completion.sql` để tạo/cập nhật procedure hoàn tất nhập. Migration 003 có thể chạy lại khi procedure đổi. Database dựng mới bằng `init.sql` đã có procedure này.

Sau migration 003, chạy `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/004_inventory_view.sql` để tạo/cập nhật `vw_TonKhoChiTiet`. View chỉ hiển thị tồn từ phiếu nhập đã hoàn tất, giữ khóa truy vết vị trí/lô/phiếu và đơn giá nhập thực tế. Database dựng mới bằng `init.sql` đã có view.

Sau migration 004, chạy một lần `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/005_outbound.sql` để thêm phiếu xuất, dòng xuất và sequence. Database dựng mới bằng `init.sql` đã có các object này.

Sau migration 005, chạy `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/006_outbound_completion.sql` để tạo/cập nhật procedure hoàn tất xuất. Test `database/tests/012_outbound_completion.sql` chứng minh FEFO, trừ tồn, thiếu mapping, thiếu tồn và chống hoàn tất lặp; migration 006 có thể chạy lại.

Sau migration 006, chạy một lần `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/007_stock_movements.sql` để tạo sổ biến động và đối chiếu/backfill nhập/xuất đã hoàn tất. Migration dừng nếu không suy được một vị trí gốc cho mỗi lô hoặc số tồn không khớp lịch sử chứng từ. Sau đó chạy `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/008_stock_movement_posting.sql` để cập nhật hai procedure ghi sổ; migration 008 có thể chạy lại. Database dựng mới bằng `init.sql` đã có cả sổ và procedure mới.

Sau migration 008, chạy `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/009_reporting_view.sql` để tạo/cập nhật `vw_BienDongTonKhoChiTiet` cho báo cáo giá trị theo lô, kho và thời gian. Migration 009 có thể chạy lại; database dựng mới bằng `init.sql` đã có view này.

Sau migration 009, chạy một lần `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/010_transfer.sql` để thêm hai bảng phiếu chuyển và sequence. Database dựng mới bằng `init.sql` đã có các object này.

Sau migration 010, chạy `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/011_transfer_completion.sql` để tạo/cập nhật `sp_HoanTatChuyenKho`. Test `database/tests/014_transfer_completion.sql` chứng minh hai phía biến động, lỗi thiếu tồn/sức chứa/bảo quản, chống hoàn tất lặp và rollback khi lỗi ở bước ghi sổ. Migration 011 có thể chạy lại.

Sau migration 011, chạy một lần `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/012_inventory_count.sql` để tạo hai bảng kiểm kê và sequence. Sau đó chạy `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/013_inventory_count_posting.sql` để tạo/cập nhật `sp_HoanTatKiemKe`. Test `database/tests/015_inventory_count_constraints.sql` và `016_inventory_count_completion.sql` kiểm tra schema, lỗi nghiệp vụ, chống chốt lặp và rollback khi ghi sổ thất bại.

Sau migration 013, chạy `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/014_count_discrepancy_view.sql` để tạo/cập nhật `vw_ChenhLechKiemKe`. View chỉ lấy dòng chênh lệch từ phiếu đã hoàn tất; test 016 kiểm tra kết quả sau điều chỉnh.

Sau migration 014, chạy một lần `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/015_return.sql` để tạo hai bảng trả hàng và sequence. Sau đó chạy `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/016_return_completion.sql` để tạo/cập nhật `sp_HoanTatTraHang`. Test 017 và 018 kiểm tra ràng buộc, giới hạn trả, vị trí hàng hư hỏng và rollback khi lỗi ghi sổ.

Sau migration 016, chạy một lần `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/017_audit.sql` để tạo bảng/index nhật ký thao tác. Test 019 kiểm tra FK, JSON check và index.

Sau migration 017, chạy `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/018_inbound_audit.sql` để cập nhật `sp_HoanTatPhieuNhap` nhận actor tùy chọn và ghi audit cùng transaction. Test 009 kiểm tra actor được ghi khi gọi với `@MaTK`.

Sau migration 018, chạy `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/019_outbound_audit.sql` để cập nhật `sp_HoanTatPhieuXuat` nhận actor tùy chọn. Test 012 kiểm tra actor audit cùng ghi sổ xuất.

Sau migration 019, chạy `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/020_transfer_audit.sql` để cập nhật `sp_HoanTatChuyenKho` nhận actor tùy chọn. Test 014 kiểm tra actor audit cùng ghi sổ chuyển.

Sau migration 020, chạy `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/021_count_audit.sql` để cập nhật `sp_HoanTatKiemKe` nhận actor tùy chọn. Test 016 kiểm tra actor audit cùng điều chỉnh tồn.

Sau migration 021, chạy `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/022_return_audit.sql` để cập nhật `sp_HoanTatTraHang` nhận actor tùy chọn. Test 018 kiểm tra actor audit cùng ghi sổ trả hàng.

Sau migration 022, chạy `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/023_inventory_functions_views.sql` để thêm năm hàm tồn/hạn dùng và bốn view tổng hợp/lịch sử. Test 020 đối chiếu lượng, giá nhập thực tế, hàng hỏng/hết hạn và lịch sử chứng từ. Database dựng mới bằng `init.sql` đã có các object này.

Sau migration 023, chạy `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/024_position_stock_guard.sql` để bảo vệ sức chứa/khu vực/loại của vị trí đã có tồn. Test 021 kiểm tra update nhiều dòng rollback nguyên tử và đổi tên hợp lệ.

Sau migration 024, chạy `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/025_application_roles.sql` để tạo bốn role database và cấp quyền theo [`security/README.md`](security/README.md). Test 022 kiểm tra quyền hiệu lực, kể cả GRANT/REVOKE/DENY, bằng user SQL tạm thời.

Sau migration 025, chạy `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/026_inventory_indexes.sql` để thêm index tra cứu lô, tồn và danh sách chứng từ. Test 023 và cách đo trước/sau ở [`indexes/README.md`](indexes/README.md).

Sau migration 026, chạy `sqlcmd -S localhost -E -C -b -d BlueStock -i database/migrations/027_inventory_guard_triggers.sql` để cài bốn trigger mới vào database **đã tồn tại** trên Windows. Database dựng mới bằng `init.sql` đã có các trigger này; không chạy lại `init.sql` trên database cũ. Với Compose, `db-init` chạy migration 027 theo cách lặp lại được mỗi lần khởi động, kể cả khi volume cũ đã tồn tại. Test `database/tests/024_inventory_guard_triggers.sql` kiểm tra nhiều dòng hợp lệ/không hợp lệ và rollback. Trigger chạy tự động khi API gọi các procedure ghi lô, tồn, sổ; Java không gọi trigger theo tên. Xem [`programmability/triggers/README.md`](programmability/triggers/README.md) để giải thích từng trigger và kịch bản báo cáo.

Sau migration 027, chạy migration 028 để thêm kết quả đối soát giá trị phiếu nhập/xuất và áp dụng lại quyền SQL hiện hành. Với Compose, `db-init` tự chạy migration 028 trên volume đã tồn tại. Test `database/tests/025_accounting_reconciliation.sql` kiểm tra cấu trúc và ràng buộc bảng.

## Cấu trúc mục tiêu

```text
database/
  schema/                 Bảng, PK, FK, CHECK, UNIQUE, DEFAULT
  migrations/             Bổ sung schema cho database local đã tồn tại
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
