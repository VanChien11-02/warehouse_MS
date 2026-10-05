# Các quyết định còn mở

Tài liệu này ngăn thành viên tự chọn khác nhau trên từng branch. Khi nhóm chốt một mục, ghi quyết định vào ADR/contract phù hợp, cập nhật nguồn liên quan rồi chuyển trạng thái tại đây.

Trạng thái: `Open`, `Accepted`, `Deferred` hoặc `Rejected`.

`DEC-001` đến `DEC-010` được chốt cho nhánh triển khai BE theo quyền kỹ thuật được giao ngày 2026-10-05 tại [ADR 0003](../../architecture/adr/0003-be-platform-contract.md). Việc tích hợp vào nhánh chung vẫn cần review của repository; trạng thái này không ghi nhận sự phê duyệt của chủ repository.

## Quyết định P0 trước khi build backend/database

| ID | Quyết định cần chốt | Đề xuất hiện tại | Ảnh hưởng | Owner | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| DEC-001 | URL resource dùng `/sanpham` hay `/san-pham` | Dùng kebab-case `/san-pham` | Frontend adapter, controller, contract | Nhánh BE | Accepted |
| DEC-002 | Có trạng thái `CHO_DUYET` hay chỉ `NHAP/DA_HOAN_THANH/DA_HUY` | Giữ ba trạng thái cho baseline | Schema, quyền, workflow, test | Nhánh BE | Accepted |
| DEC-003 | Cách lưu thời điểm | Lưu UTC, trả ISO-8601 với `Z`; ngày nghiệp vụ theo Asia/Bangkok | SQL type, Jackson, báo cáo | Nhánh BE | Accepted |
| DEC-004 | `409` hay `422` cho validation nghiệp vụ | `409` cho conflict trạng thái/tồn; `422` cho field business validation | Error handler và client | Nhánh BE | Accepted |
| DEC-005 | Procedure trả lỗi bằng gì | `THROW` số `51000–51999`, JDBC ánh xạ mã lỗi | T-SQL/JDBC/API | Nhánh BE | Accepted |
| DEC-006 | Tên database và schema mặc định | `BlueStock`, schema `dbo` cho baseline | Script/config/demo | Nhánh BE | Accepted |
| DEC-007 | Quy tắc sinh mã nghiệp vụ | Client nhập mã danh mục; server sinh mã chứng từ/lô bằng sequence | Schema, DTO, UX | Nhánh BE | Accepted |
| DEC-008 | Precision tiền | `DECIMAL(19,4)`/`BigDecimal` | Schema, BigDecimal, báo cáo | Nhánh BE | Accepted |
| DEC-009 | Cơ chế đăng nhập ứng dụng | Session cookie `HttpOnly` và CSRF token | Security, frontend storage, CORS | Nhánh BE | Accepted |
| DEC-010 | Runner database chuẩn | `sqlcmd -b` từ root repository; SSMS SQLCMD mode | `init.sql`, CI, hướng dẫn demo | Nhánh BE | Accepted |

## Quyết định nghiệp vụ cần chốt trước module liên quan

| ID | Quyết định cần chốt | Đề xuất hiện tại | Cần trước | Trạng thái |
| --- | --- | --- | --- | --- |
| DEC-011 | Có bắt buộc nhà cung cấp/đối tác liên kết sản phẩm không | Bật cho luồng hoàn tất, cho phép quản lý mapping ở danh mục | INB-01, OUT-01 | Open |
| DEC-012 | Đơn vị của `SucChua` | Tổng số đơn vị sản phẩm tại vị trí hoặc đơn vị thể tích/khối lượng | LOC-01, TRF-01 | Open |
| DEC-013 | Tương thích loại bảo quản | Enum/mapping nào quyết định vị trí nhận được sản phẩm | LOC-01, INB-01 | Open |
| DEC-014 | Lô không có hạn sử dụng trong FEFO | Xếp sau lô có hạn còn hiệu lực | OUT-01 | Open |
| DEC-015 | Ai được hoàn tất từng chứng từ | QuanLyKho và quyền cụ thể của NhanVienKho | SEC-01 và mọi transaction | Open |
| DEC-016 | Chính sách vị trí hàng hư hỏng khi trả | Chỉ vị trí cách ly/hư hỏng | RET-01 | Open |
| DEC-017 | Nguồn giá tính giá trị tồn | Giá nhập thực tế theo lô hoặc phương pháp khác | REP-01 | Open |
| DEC-018 | Ngưỡng/lý do chênh lệch kiểm kê | Mọi chênh lệch phải có lý do | CNT-01 | Open |

## Quyết định phát triển và tích hợp

| ID | Quyết định cần chốt | Đề xuất hiện tại | Trạng thái |
| --- | --- | --- | --- |
| DEC-019 | Nhánh tích hợp | PR trực tiếp vào `main` nếu gate ổn; chỉ thêm `develop` khi nhóm thực sự dùng | Open |
| DEC-020 | Reviewer từng workstream | Reviewer khác owner, ưu tiên theo trách nhiệm rubric | Open |
| DEC-021 | Người thực hiện tách frontend `GOV-03` | Trưởng nhóm hoặc TV4 trước khi UI phát triển song song | Open |
| DEC-022 | Migration tool sau baseline | Chưa thêm Flyway/Liquibase; `init.sql` là điểm vào baseline | Deferred |
| DEC-023 | Docker/local orchestration | Không bắt buộc cho baseline; chỉ thêm nếu giúp demo và có owner | Deferred |

## Cách ghi quyết định

Khi một mục được chốt:

1. Ghi người quyết định và ngày.
2. Chuyển trạng thái sang `Accepted` hoặc `Rejected`.
3. Đưa quyết định bền vững vào ADR, ERD hoặc contract tương ứng.
4. Cập nhật code/test/tài liệu bị ảnh hưởng trong cùng PR.
5. Không xóa lịch sử quyết định chỉ vì phương án đã thay đổi.

## Biên bản ngắn

| ID | Kết quả | Người/ngày | Tài liệu nguồn |
| --- | --- | --- | --- |
| DEC-001–010 | Quy ước nền tảng cho nhánh triển khai BE | Nhánh BE / 2026-10-05 | [ADR 0003](../../architecture/adr/0003-be-platform-contract.md) |
